
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
ffffffffc0200062:	7a0050ef          	jal	ra,ffffffffc0205802 <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	7c258593          	addi	a1,a1,1986 # ffffffffc0205830 <etext+0x4>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	7da50513          	addi	a0,a0,2010 # ffffffffc0205850 <etext+0x24>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	7d8020ef          	jal	ra,ffffffffc020285e <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	317030ef          	jal	ra,ffffffffc0203ba8 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	6bf040ef          	jal	ra,ffffffffc0204f54 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	04a050ef          	jal	ra,ffffffffc02050ec <cpu_idle>

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
ffffffffc02000c0:	79c50513          	addi	a0,a0,1948 # ffffffffc0205858 <etext+0x2c>
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
ffffffffc0200188:	256050ef          	jal	ra,ffffffffc02053de <vprintfmt>
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
ffffffffc02001be:	220050ef          	jal	ra,ffffffffc02053de <vprintfmt>
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
ffffffffc0200222:	64250513          	addi	a0,a0,1602 # ffffffffc0205860 <etext+0x34>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	64c50513          	addi	a0,a0,1612 # ffffffffc0205880 <etext+0x54>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	5ec58593          	addi	a1,a1,1516 # ffffffffc020582c <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	65850513          	addi	a0,a0,1624 # ffffffffc02058a0 <etext+0x74>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000a6597          	auipc	a1,0xa6
ffffffffc0200258:	01458593          	addi	a1,a1,20 # ffffffffc02a6268 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	66450513          	addi	a0,a0,1636 # ffffffffc02058c0 <etext+0x94>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000aa597          	auipc	a1,0xaa
ffffffffc020026c:	4a458593          	addi	a1,a1,1188 # ffffffffc02aa70c <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	67050513          	addi	a0,a0,1648 # ffffffffc02058e0 <etext+0xb4>
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
ffffffffc02002a2:	66250513          	addi	a0,a0,1634 # ffffffffc0205900 <etext+0xd4>
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
ffffffffc02002b0:	68460613          	addi	a2,a2,1668 # ffffffffc0205930 <etext+0x104>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	69050513          	addi	a0,a0,1680 # ffffffffc0205948 <etext+0x11c>
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
ffffffffc02002cc:	69860613          	addi	a2,a2,1688 # ffffffffc0205960 <etext+0x134>
ffffffffc02002d0:	00005597          	auipc	a1,0x5
ffffffffc02002d4:	6b058593          	addi	a1,a1,1712 # ffffffffc0205980 <etext+0x154>
ffffffffc02002d8:	00005517          	auipc	a0,0x5
ffffffffc02002dc:	6b050513          	addi	a0,a0,1712 # ffffffffc0205988 <etext+0x15c>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00005617          	auipc	a2,0x5
ffffffffc02002ea:	6b260613          	addi	a2,a2,1714 # ffffffffc0205998 <etext+0x16c>
ffffffffc02002ee:	00005597          	auipc	a1,0x5
ffffffffc02002f2:	6d258593          	addi	a1,a1,1746 # ffffffffc02059c0 <etext+0x194>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	69250513          	addi	a0,a0,1682 # ffffffffc0205988 <etext+0x15c>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00005617          	auipc	a2,0x5
ffffffffc0200306:	6ce60613          	addi	a2,a2,1742 # ffffffffc02059d0 <etext+0x1a4>
ffffffffc020030a:	00005597          	auipc	a1,0x5
ffffffffc020030e:	6e658593          	addi	a1,a1,1766 # ffffffffc02059f0 <etext+0x1c4>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	67650513          	addi	a0,a0,1654 # ffffffffc0205988 <etext+0x15c>
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
ffffffffc0200350:	6b450513          	addi	a0,a0,1716 # ffffffffc0205a00 <etext+0x1d4>
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
ffffffffc0200372:	6ba50513          	addi	a0,a0,1722 # ffffffffc0205a28 <etext+0x1fc>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00005c17          	auipc	s8,0x5
ffffffffc0200388:	714c0c13          	addi	s8,s8,1812 # ffffffffc0205a98 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00005917          	auipc	s2,0x5
ffffffffc0200390:	6c490913          	addi	s2,s2,1732 # ffffffffc0205a50 <etext+0x224>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00005497          	auipc	s1,0x5
ffffffffc0200398:	6c448493          	addi	s1,s1,1732 # ffffffffc0205a58 <etext+0x22c>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00005b17          	auipc	s6,0x5
ffffffffc02003a2:	6c2b0b13          	addi	s6,s6,1730 # ffffffffc0205a60 <etext+0x234>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	5daa0a13          	addi	s4,s4,1498 # ffffffffc0205980 <etext+0x154>
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
ffffffffc02003cc:	6d0d0d13          	addi	s10,s10,1744 # ffffffffc0205a98 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	3d2050ef          	jal	ra,ffffffffc02057a8 <strcmp>
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
ffffffffc02003ea:	3be050ef          	jal	ra,ffffffffc02057a8 <strcmp>
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
ffffffffc0200428:	3c4050ef          	jal	ra,ffffffffc02057ec <strchr>
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
ffffffffc0200466:	386050ef          	jal	ra,ffffffffc02057ec <strchr>
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
ffffffffc0200484:	60050513          	addi	a0,a0,1536 # ffffffffc0205a80 <etext+0x254>
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
ffffffffc02004c0:	62450513          	addi	a0,a0,1572 # ffffffffc0205ae0 <commands+0x48>
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
ffffffffc02004d6:	70e50513          	addi	a0,a0,1806 # ffffffffc0206be0 <default_pmm_manager+0x540>
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
ffffffffc020050a:	5fa50513          	addi	a0,a0,1530 # ffffffffc0205b00 <commands+0x68>
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
ffffffffc020052a:	6ba50513          	addi	a0,a0,1722 # ffffffffc0206be0 <default_pmm_manager+0x540>
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
ffffffffc0200564:	5c050513          	addi	a0,a0,1472 # ffffffffc0205b20 <commands+0x88>
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
ffffffffc0200604:	54050513          	addi	a0,a0,1344 # ffffffffc0205b40 <commands+0xa8>
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
ffffffffc0200632:	52250513          	addi	a0,a0,1314 # ffffffffc0205b50 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	51c50513          	addi	a0,a0,1308 # ffffffffc0205b60 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	52450513          	addi	a0,a0,1316 # ffffffffc0205b78 <commands+0xe0>
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
ffffffffc0200712:	4ba90913          	addi	s2,s2,1210 # ffffffffc0205bc8 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	4a448493          	addi	s1,s1,1188 # ffffffffc0205bc0 <commands+0x128>
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
ffffffffc0200774:	4d050513          	addi	a0,a0,1232 # ffffffffc0205c40 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	4fc50513          	addi	a0,a0,1276 # ffffffffc0205c78 <commands+0x1e0>
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
ffffffffc02007c0:	3dc50513          	addi	a0,a0,988 # ffffffffc0205b98 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	797040ef          	jal	ra,ffffffffc0205760 <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	7ef040ef          	jal	ra,ffffffffc02057c6 <strncmp>
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
ffffffffc020086e:	73b040ef          	jal	ra,ffffffffc02057a8 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	34e50513          	addi	a0,a0,846 # ffffffffc0205bd0 <commands+0x138>
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
ffffffffc0200954:	2a050513          	addi	a0,a0,672 # ffffffffc0205bf0 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	2a650513          	addi	a0,a0,678 # ffffffffc0205c08 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	2b450513          	addi	a0,a0,692 # ffffffffc0205c28 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	2f850513          	addi	a0,a0,760 # ffffffffc0205c78 <commands+0x1e0>
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
ffffffffc02009c4:	5cc78793          	addi	a5,a5,1484 # ffffffffc0200f8c <__alltraps>
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
ffffffffc02009e2:	2b250513          	addi	a0,a0,690 # ffffffffc0205c90 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	2ba50513          	addi	a0,a0,698 # ffffffffc0205ca8 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	2c450513          	addi	a0,a0,708 # ffffffffc0205cc0 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	2ce50513          	addi	a0,a0,718 # ffffffffc0205cd8 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	2d850513          	addi	a0,a0,728 # ffffffffc0205cf0 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	2e250513          	addi	a0,a0,738 # ffffffffc0205d08 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	2ec50513          	addi	a0,a0,748 # ffffffffc0205d20 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	2f650513          	addi	a0,a0,758 # ffffffffc0205d38 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	30050513          	addi	a0,a0,768 # ffffffffc0205d50 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	30a50513          	addi	a0,a0,778 # ffffffffc0205d68 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	31450513          	addi	a0,a0,788 # ffffffffc0205d80 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	31e50513          	addi	a0,a0,798 # ffffffffc0205d98 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	32850513          	addi	a0,a0,808 # ffffffffc0205db0 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	33250513          	addi	a0,a0,818 # ffffffffc0205dc8 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	33c50513          	addi	a0,a0,828 # ffffffffc0205de0 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	34650513          	addi	a0,a0,838 # ffffffffc0205df8 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	35050513          	addi	a0,a0,848 # ffffffffc0205e10 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	35a50513          	addi	a0,a0,858 # ffffffffc0205e28 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	36450513          	addi	a0,a0,868 # ffffffffc0205e40 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	36e50513          	addi	a0,a0,878 # ffffffffc0205e58 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	37850513          	addi	a0,a0,888 # ffffffffc0205e70 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	38250513          	addi	a0,a0,898 # ffffffffc0205e88 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	38c50513          	addi	a0,a0,908 # ffffffffc0205ea0 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	39650513          	addi	a0,a0,918 # ffffffffc0205eb8 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	3a050513          	addi	a0,a0,928 # ffffffffc0205ed0 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	3aa50513          	addi	a0,a0,938 # ffffffffc0205ee8 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	3b450513          	addi	a0,a0,948 # ffffffffc0205f00 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	3be50513          	addi	a0,a0,958 # ffffffffc0205f18 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	3c850513          	addi	a0,a0,968 # ffffffffc0205f30 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	3d250513          	addi	a0,a0,978 # ffffffffc0205f48 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	3dc50513          	addi	a0,a0,988 # ffffffffc0205f60 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	3e250513          	addi	a0,a0,994 # ffffffffc0205f78 <commands+0x4e0>
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
ffffffffc0200bb0:	3e450513          	addi	a0,a0,996 # ffffffffc0205f90 <commands+0x4f8>
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
ffffffffc0200bc8:	3e450513          	addi	a0,a0,996 # ffffffffc0205fa8 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	3ec50513          	addi	a0,a0,1004 # ffffffffc0205fc0 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	3f450513          	addi	a0,a0,1012 # ffffffffc0205fd8 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	3f050513          	addi	a0,a0,1008 # ffffffffc0205fe8 <commands+0x550>
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
ffffffffc0200c10:	08f76463          	bltu	a4,a5,ffffffffc0200c98 <interrupt_handler+0x92>
ffffffffc0200c14:	00005717          	auipc	a4,0x5
ffffffffc0200c18:	48c70713          	addi	a4,a4,1164 # ffffffffc02060a0 <commands+0x608>
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
ffffffffc0200c2a:	43a50513          	addi	a0,a0,1082 # ffffffffc0206060 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00005517          	auipc	a0,0x5
ffffffffc0200c36:	40e50513          	addi	a0,a0,1038 # ffffffffc0206040 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	3c250513          	addi	a0,a0,962 # ffffffffc0206000 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00005517          	auipc	a0,0x5
ffffffffc0200c4e:	3d650513          	addi	a0,a0,982 # ffffffffc0206020 <commands+0x588>
ffffffffc0200c52:	d42ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200c56:	1141                	addi	sp,sp,-16
ffffffffc0200c58:	e406                	sd	ra,8(sp)
        /* 时间片轮转： 
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
         clock_set_next_event();
ffffffffc0200c5a:	919ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>
            ticks++;
ffffffffc0200c5e:	000aa797          	auipc	a5,0xaa
ffffffffc0200c62:	a3a78793          	addi	a5,a5,-1478 # ffffffffc02aa698 <ticks>
ffffffffc0200c66:	6398                	ld	a4,0(a5)
ffffffffc0200c68:	0705                	addi	a4,a4,1
ffffffffc0200c6a:	e398                	sd	a4,0(a5)
            if(ticks%TICK_NUM==0)
ffffffffc0200c6c:	639c                	ld	a5,0(a5)
ffffffffc0200c6e:	06400713          	li	a4,100
ffffffffc0200c72:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200c76:	eb81                	bnez	a5,ffffffffc0200c86 <interrupt_handler+0x80>
            {   
                if(current!=NULL)
ffffffffc0200c78:	000aa797          	auipc	a5,0xaa
ffffffffc0200c7c:	a787b783          	ld	a5,-1416(a5) # ffffffffc02aa6f0 <current>
ffffffffc0200c80:	c399                	beqz	a5,ffffffffc0200c86 <interrupt_handler+0x80>
                {
                    current->need_resched = 1;
ffffffffc0200c82:	4705                	li	a4,1
ffffffffc0200c84:	ef98                	sd	a4,24(a5)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c86:	60a2                	ld	ra,8(sp)
ffffffffc0200c88:	0141                	addi	sp,sp,16
ffffffffc0200c8a:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c8c:	00005517          	auipc	a0,0x5
ffffffffc0200c90:	3f450513          	addi	a0,a0,1012 # ffffffffc0206080 <commands+0x5e8>
ffffffffc0200c94:	d00ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c98:	b731                	j	ffffffffc0200ba4 <print_trapframe>

ffffffffc0200c9a <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c9a:	11853783          	ld	a5,280(a0)
{
ffffffffc0200c9e:	7139                	addi	sp,sp,-64
ffffffffc0200ca0:	f822                	sd	s0,48(sp)
ffffffffc0200ca2:	fc06                	sd	ra,56(sp)
ffffffffc0200ca4:	f426                	sd	s1,40(sp)
ffffffffc0200ca6:	f04a                	sd	s2,32(sp)
ffffffffc0200ca8:	ec4e                	sd	s3,24(sp)
ffffffffc0200caa:	e852                	sd	s4,16(sp)
ffffffffc0200cac:	473d                	li	a4,15
ffffffffc0200cae:	842a                	mv	s0,a0
ffffffffc0200cb0:	12f76863          	bltu	a4,a5,ffffffffc0200de0 <exception_handler+0x146>
ffffffffc0200cb4:	00005717          	auipc	a4,0x5
ffffffffc0200cb8:	5ec70713          	addi	a4,a4,1516 # ffffffffc02062a0 <commands+0x808>
ffffffffc0200cbc:	078a                	slli	a5,a5,0x2
ffffffffc0200cbe:	97ba                	add	a5,a5,a4
ffffffffc0200cc0:	439c                	lw	a5,0(a5)
ffffffffc0200cc2:	97ba                	add	a5,a5,a4
ffffffffc0200cc4:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200cc6:	00005517          	auipc	a0,0x5
ffffffffc0200cca:	4f250513          	addi	a0,a0,1266 # ffffffffc02061b8 <commands+0x720>
ffffffffc0200cce:	cc6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200cd2:	10843783          	ld	a5,264(s0)
        }
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cd6:	70e2                	ld	ra,56(sp)
ffffffffc0200cd8:	74a2                	ld	s1,40(sp)
        tf->epc += 4;
ffffffffc0200cda:	0791                	addi	a5,a5,4
ffffffffc0200cdc:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200ce0:	7442                	ld	s0,48(sp)
ffffffffc0200ce2:	7902                	ld	s2,32(sp)
ffffffffc0200ce4:	69e2                	ld	s3,24(sp)
ffffffffc0200ce6:	6a42                	ld	s4,16(sp)
ffffffffc0200ce8:	6121                	addi	sp,sp,64
        syscall();
ffffffffc0200cea:	5f20406f          	j	ffffffffc02052dc <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cee:	00005517          	auipc	a0,0x5
ffffffffc0200cf2:	4ea50513          	addi	a0,a0,1258 # ffffffffc02061d8 <commands+0x740>
}
ffffffffc0200cf6:	7442                	ld	s0,48(sp)
ffffffffc0200cf8:	70e2                	ld	ra,56(sp)
ffffffffc0200cfa:	74a2                	ld	s1,40(sp)
ffffffffc0200cfc:	7902                	ld	s2,32(sp)
ffffffffc0200cfe:	69e2                	ld	s3,24(sp)
ffffffffc0200d00:	6a42                	ld	s4,16(sp)
ffffffffc0200d02:	6121                	addi	sp,sp,64
        cprintf("Instruction access fault\n");
ffffffffc0200d04:	c90ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d08:	00005517          	auipc	a0,0x5
ffffffffc0200d0c:	4f050513          	addi	a0,a0,1264 # ffffffffc02061f8 <commands+0x760>
ffffffffc0200d10:	b7dd                	j	ffffffffc0200cf6 <exception_handler+0x5c>
        cprintf("Instruction page fault\n");
ffffffffc0200d12:	00005517          	auipc	a0,0x5
ffffffffc0200d16:	50650513          	addi	a0,a0,1286 # ffffffffc0206218 <commands+0x780>
ffffffffc0200d1a:	bff1                	j	ffffffffc0200cf6 <exception_handler+0x5c>
        cprintf("Load page fault\n");
ffffffffc0200d1c:	00005517          	auipc	a0,0x5
ffffffffc0200d20:	51450513          	addi	a0,a0,1300 # ffffffffc0206230 <commands+0x798>
ffffffffc0200d24:	bfc9                	j	ffffffffc0200cf6 <exception_handler+0x5c>
            if (current != NULL && current->mm != NULL) {
ffffffffc0200d26:	000aa917          	auipc	s2,0xaa
ffffffffc0200d2a:	9ca90913          	addi	s2,s2,-1590 # ffffffffc02aa6f0 <current>
ffffffffc0200d2e:	00093783          	ld	a5,0(s2)
                uintptr_t addr = tf->tval;
ffffffffc0200d32:	11053583          	ld	a1,272(a0)
            if (current != NULL && current->mm != NULL) {
ffffffffc0200d36:	c795                	beqz	a5,ffffffffc0200d62 <exception_handler+0xc8>
ffffffffc0200d38:	779c                	ld	a5,40(a5)
ffffffffc0200d3a:	c785                	beqz	a5,ffffffffc0200d62 <exception_handler+0xc8>
                struct Page *old_page = get_page(current->mm->pgdir, aligned_addr, &ptep);
ffffffffc0200d3c:	6f88                	ld	a0,24(a5)
                uintptr_t aligned_addr = ROUNDDOWN(addr, PGSIZE); // 页对齐是必须的
ffffffffc0200d3e:	74fd                	lui	s1,0xfffff
ffffffffc0200d40:	8ced                	and	s1,s1,a1
                struct Page *old_page = get_page(current->mm->pgdir, aligned_addr, &ptep);
ffffffffc0200d42:	0030                	addi	a2,sp,8
ffffffffc0200d44:	85a6                	mv	a1,s1
                pte_t *ptep = NULL;
ffffffffc0200d46:	e402                	sd	zero,8(sp)
                struct Page *old_page = get_page(current->mm->pgdir, aligned_addr, &ptep);
ffffffffc0200d48:	558010ef          	jal	ra,ffffffffc02022a0 <get_page>
ffffffffc0200d4c:	89aa                	mv	s3,a0
                if (old_page != NULL && ptep != NULL && (*ptep & PTE_V) && 
ffffffffc0200d4e:	c901                	beqz	a0,ffffffffc0200d5e <exception_handler+0xc4>
ffffffffc0200d50:	67a2                	ld	a5,8(sp)
ffffffffc0200d52:	c791                	beqz	a5,ffffffffc0200d5e <exception_handler+0xc4>
ffffffffc0200d54:	639c                	ld	a5,0(a5)
ffffffffc0200d56:	4705                	li	a4,1
ffffffffc0200d58:	8b95                	andi	a5,a5,5
ffffffffc0200d5a:	0ae78863          	beq	a5,a4,ffffffffc0200e0a <exception_handler+0x170>
            cprintf("Store fault at %p (epc: %p)\n", tf->tval, tf->epc);
ffffffffc0200d5e:	11043583          	ld	a1,272(s0)
ffffffffc0200d62:	10843603          	ld	a2,264(s0)
}
ffffffffc0200d66:	7442                	ld	s0,48(sp)
ffffffffc0200d68:	70e2                	ld	ra,56(sp)
ffffffffc0200d6a:	74a2                	ld	s1,40(sp)
ffffffffc0200d6c:	7902                	ld	s2,32(sp)
ffffffffc0200d6e:	69e2                	ld	s3,24(sp)
ffffffffc0200d70:	6a42                	ld	s4,16(sp)
            cprintf("Store fault at %p (epc: %p)\n", tf->tval, tf->epc);
ffffffffc0200d72:	00005517          	auipc	a0,0x5
ffffffffc0200d76:	50e50513          	addi	a0,a0,1294 # ffffffffc0206280 <commands+0x7e8>
}
ffffffffc0200d7a:	6121                	addi	sp,sp,64
            cprintf("Store fault at %p (epc: %p)\n", tf->tval, tf->epc);
ffffffffc0200d7c:	c18ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d80:	00005517          	auipc	a0,0x5
ffffffffc0200d84:	35050513          	addi	a0,a0,848 # ffffffffc02060d0 <commands+0x638>
ffffffffc0200d88:	b7bd                	j	ffffffffc0200cf6 <exception_handler+0x5c>
        cprintf("Instruction access fault\n");
ffffffffc0200d8a:	00005517          	auipc	a0,0x5
ffffffffc0200d8e:	36650513          	addi	a0,a0,870 # ffffffffc02060f0 <commands+0x658>
ffffffffc0200d92:	b795                	j	ffffffffc0200cf6 <exception_handler+0x5c>
        cprintf("Illegal instruction\n");
ffffffffc0200d94:	00005517          	auipc	a0,0x5
ffffffffc0200d98:	37c50513          	addi	a0,a0,892 # ffffffffc0206110 <commands+0x678>
ffffffffc0200d9c:	bfa9                	j	ffffffffc0200cf6 <exception_handler+0x5c>
        cprintf("Breakpoint\n");
ffffffffc0200d9e:	00005517          	auipc	a0,0x5
ffffffffc0200da2:	38a50513          	addi	a0,a0,906 # ffffffffc0206128 <commands+0x690>
ffffffffc0200da6:	beeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200daa:	6458                	ld	a4,136(s0)
ffffffffc0200dac:	47a9                	li	a5,10
ffffffffc0200dae:	0ef70f63          	beq	a4,a5,ffffffffc0200eac <exception_handler+0x212>
}
ffffffffc0200db2:	70e2                	ld	ra,56(sp)
ffffffffc0200db4:	7442                	ld	s0,48(sp)
ffffffffc0200db6:	74a2                	ld	s1,40(sp)
ffffffffc0200db8:	7902                	ld	s2,32(sp)
ffffffffc0200dba:	69e2                	ld	s3,24(sp)
ffffffffc0200dbc:	6a42                	ld	s4,16(sp)
ffffffffc0200dbe:	6121                	addi	sp,sp,64
ffffffffc0200dc0:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200dc2:	00005517          	auipc	a0,0x5
ffffffffc0200dc6:	37650513          	addi	a0,a0,886 # ffffffffc0206138 <commands+0x6a0>
ffffffffc0200dca:	b735                	j	ffffffffc0200cf6 <exception_handler+0x5c>
        cprintf("Load access fault\n");
ffffffffc0200dcc:	00005517          	auipc	a0,0x5
ffffffffc0200dd0:	38c50513          	addi	a0,a0,908 # ffffffffc0206158 <commands+0x6c0>
ffffffffc0200dd4:	b70d                	j	ffffffffc0200cf6 <exception_handler+0x5c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200dd6:	00005517          	auipc	a0,0x5
ffffffffc0200dda:	3ca50513          	addi	a0,a0,970 # ffffffffc02061a0 <commands+0x708>
ffffffffc0200dde:	bf21                	j	ffffffffc0200cf6 <exception_handler+0x5c>
        print_trapframe(tf);
ffffffffc0200de0:	8522                	mv	a0,s0
}
ffffffffc0200de2:	7442                	ld	s0,48(sp)
ffffffffc0200de4:	70e2                	ld	ra,56(sp)
ffffffffc0200de6:	74a2                	ld	s1,40(sp)
ffffffffc0200de8:	7902                	ld	s2,32(sp)
ffffffffc0200dea:	69e2                	ld	s3,24(sp)
ffffffffc0200dec:	6a42                	ld	s4,16(sp)
ffffffffc0200dee:	6121                	addi	sp,sp,64
        print_trapframe(tf);
ffffffffc0200df0:	bb55                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200df2:	00005617          	auipc	a2,0x5
ffffffffc0200df6:	37e60613          	addi	a2,a2,894 # ffffffffc0206170 <commands+0x6d8>
ffffffffc0200dfa:	0c300593          	li	a1,195
ffffffffc0200dfe:	00005517          	auipc	a0,0x5
ffffffffc0200e02:	38a50513          	addi	a0,a0,906 # ffffffffc0206188 <commands+0x6f0>
ffffffffc0200e06:	e88ff0ef          	jal	ra,ffffffffc020048e <__panic>
                    !(*ptep & PTE_W) && page_ref(old_page) > 1) {
ffffffffc0200e0a:	4118                	lw	a4,0(a0)
ffffffffc0200e0c:	f4e7d9e3          	bge	a5,a4,ffffffffc0200d5e <exception_handler+0xc4>
                    struct Page *new_page = alloc_page();
ffffffffc0200e10:	4505                	li	a0,1
ffffffffc0200e12:	1ae010ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc0200e16:	8a2a                	mv	s4,a0
                    if (new_page == NULL) break; // 分配失败，走默认错误
ffffffffc0200e18:	dd49                	beqz	a0,ffffffffc0200db2 <exception_handler+0x118>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200e1a:	000aa797          	auipc	a5,0xaa
ffffffffc0200e1e:	8be7b783          	ld	a5,-1858(a5) # ffffffffc02aa6d8 <pages>
ffffffffc0200e22:	40f506b3          	sub	a3,a0,a5
ffffffffc0200e26:	00007597          	auipc	a1,0x7
ffffffffc0200e2a:	b2a5b583          	ld	a1,-1238(a1) # ffffffffc0207950 <nbase>
ffffffffc0200e2e:	8699                	srai	a3,a3,0x6
}

static inline void *
page2kva(struct Page *page)
{
    return KADDR(page2pa(page));
ffffffffc0200e30:	577d                	li	a4,-1
    return page - pages + nbase;
ffffffffc0200e32:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0200e34:	8331                	srli	a4,a4,0xc
ffffffffc0200e36:	00e6f533          	and	a0,a3,a4
ffffffffc0200e3a:	000aa617          	auipc	a2,0xaa
ffffffffc0200e3e:	89663603          	ld	a2,-1898(a2) # ffffffffc02aa6d0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e42:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0200e44:	0ac57363          	bgeu	a0,a2,ffffffffc0200eea <exception_handler+0x250>
    return page - pages + nbase;
ffffffffc0200e48:	40f987b3          	sub	a5,s3,a5
ffffffffc0200e4c:	8799                	srai	a5,a5,0x6
ffffffffc0200e4e:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc0200e50:	8f7d                	and	a4,a4,a5
ffffffffc0200e52:	000aa597          	auipc	a1,0xaa
ffffffffc0200e56:	8965b583          	ld	a1,-1898(a1) # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc0200e5a:	00b68533          	add	a0,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e5e:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0200e62:	08c77463          	bgeu	a4,a2,ffffffffc0200eea <exception_handler+0x250>
                    memcpy(page2kva(new_page), page2kva(old_page), PGSIZE);
ffffffffc0200e66:	95b6                	add	a1,a1,a3
ffffffffc0200e68:	6605                	lui	a2,0x1
ffffffffc0200e6a:	1ab040ef          	jal	ra,ffffffffc0205814 <memcpy>
                    page_remove(current->mm->pgdir, aligned_addr);
ffffffffc0200e6e:	00093783          	ld	a5,0(s2)
                    uint32_t new_perm = (*ptep & (PTE_R | PTE_X | PTE_U)) | PTE_W;
ffffffffc0200e72:	6722                	ld	a4,8(sp)
                    page_remove(current->mm->pgdir, aligned_addr);
ffffffffc0200e74:	85a6                	mv	a1,s1
ffffffffc0200e76:	779c                	ld	a5,40(a5)
                    uint32_t new_perm = (*ptep & (PTE_R | PTE_X | PTE_U)) | PTE_W;
ffffffffc0200e78:	00073983          	ld	s3,0(a4)
                    page_remove(current->mm->pgdir, aligned_addr);
ffffffffc0200e7c:	6f88                	ld	a0,24(a5)
                    uint32_t new_perm = (*ptep & (PTE_R | PTE_X | PTE_U)) | PTE_W;
ffffffffc0200e7e:	01a9f993          	andi	s3,s3,26
ffffffffc0200e82:	0049e993          	ori	s3,s3,4
                    page_remove(current->mm->pgdir, aligned_addr);
ffffffffc0200e86:	047010ef          	jal	ra,ffffffffc02026cc <page_remove>
                    if (page_insert(current->mm->pgdir, new_page, aligned_addr, new_perm) == 0) {
ffffffffc0200e8a:	00093783          	ld	a5,0(s2)
ffffffffc0200e8e:	86ce                	mv	a3,s3
ffffffffc0200e90:	8626                	mv	a2,s1
ffffffffc0200e92:	779c                	ld	a5,40(a5)
ffffffffc0200e94:	85d2                	mv	a1,s4
ffffffffc0200e96:	6f88                	ld	a0,24(a5)
ffffffffc0200e98:	0d1010ef          	jal	ra,ffffffffc0202768 <page_insert>
ffffffffc0200e9c:	cd1d                	beqz	a0,ffffffffc0200eda <exception_handler+0x240>
                        free_page(new_page); // 映射失败，释放新页（防泄漏）
ffffffffc0200e9e:	4585                	li	a1,1
ffffffffc0200ea0:	8552                	mv	a0,s4
ffffffffc0200ea2:	15c010ef          	jal	ra,ffffffffc0201ffe <free_pages>
            cprintf("Store fault at %p (epc: %p)\n", tf->tval, tf->epc);
ffffffffc0200ea6:	11043583          	ld	a1,272(s0)
ffffffffc0200eaa:	bd65                	j	ffffffffc0200d62 <exception_handler+0xc8>
            tf->epc += 4;
ffffffffc0200eac:	10843783          	ld	a5,264(s0)
ffffffffc0200eb0:	0791                	addi	a5,a5,4
ffffffffc0200eb2:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200eb6:	426040ef          	jal	ra,ffffffffc02052dc <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200eba:	000aa797          	auipc	a5,0xaa
ffffffffc0200ebe:	8367b783          	ld	a5,-1994(a5) # ffffffffc02aa6f0 <current>
ffffffffc0200ec2:	6b9c                	ld	a5,16(a5)
ffffffffc0200ec4:	8522                	mv	a0,s0
}
ffffffffc0200ec6:	7442                	ld	s0,48(sp)
ffffffffc0200ec8:	70e2                	ld	ra,56(sp)
ffffffffc0200eca:	74a2                	ld	s1,40(sp)
ffffffffc0200ecc:	7902                	ld	s2,32(sp)
ffffffffc0200ece:	69e2                	ld	s3,24(sp)
ffffffffc0200ed0:	6a42                	ld	s4,16(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200ed2:	6589                	lui	a1,0x2
ffffffffc0200ed4:	95be                	add	a1,a1,a5
}
ffffffffc0200ed6:	6121                	addi	sp,sp,64
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200ed8:	a249                	j	ffffffffc020105a <kernel_execve_ret>
                        tlb_invalidate(current->mm->pgdir, aligned_addr); // 刷新TLB
ffffffffc0200eda:	00093783          	ld	a5,0(s2)
ffffffffc0200ede:	85a6                	mv	a1,s1
ffffffffc0200ee0:	779c                	ld	a5,40(a5)
ffffffffc0200ee2:	6f88                	ld	a0,24(a5)
ffffffffc0200ee4:	087020ef          	jal	ra,ffffffffc020376a <tlb_invalidate>
                        return; // 重试写指令（核心：直接返回，epc会重新执行错误指令）
ffffffffc0200ee8:	b5e9                	j	ffffffffc0200db2 <exception_handler+0x118>
ffffffffc0200eea:	00005617          	auipc	a2,0x5
ffffffffc0200eee:	35e60613          	addi	a2,a2,862 # ffffffffc0206248 <commands+0x7b0>
ffffffffc0200ef2:	07100593          	li	a1,113
ffffffffc0200ef6:	00005517          	auipc	a0,0x5
ffffffffc0200efa:	37a50513          	addi	a0,a0,890 # ffffffffc0206270 <commands+0x7d8>
ffffffffc0200efe:	d90ff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200f02 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200f02:	1101                	addi	sp,sp,-32
ffffffffc0200f04:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200f06:	000a9417          	auipc	s0,0xa9
ffffffffc0200f0a:	7ea40413          	addi	s0,s0,2026 # ffffffffc02aa6f0 <current>
ffffffffc0200f0e:	6018                	ld	a4,0(s0)
{
ffffffffc0200f10:	ec06                	sd	ra,24(sp)
ffffffffc0200f12:	e426                	sd	s1,8(sp)
ffffffffc0200f14:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200f16:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200f1a:	cf1d                	beqz	a4,ffffffffc0200f58 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200f1c:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200f20:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200f24:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200f26:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200f2a:	0206c463          	bltz	a3,ffffffffc0200f52 <trap+0x50>
        exception_handler(tf);
ffffffffc0200f2e:	d6dff0ef          	jal	ra,ffffffffc0200c9a <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200f32:	601c                	ld	a5,0(s0)
ffffffffc0200f34:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200f38:	e499                	bnez	s1,ffffffffc0200f46 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200f3a:	0b07a703          	lw	a4,176(a5)
ffffffffc0200f3e:	8b05                	andi	a4,a4,1
ffffffffc0200f40:	e329                	bnez	a4,ffffffffc0200f82 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200f42:	6f9c                	ld	a5,24(a5)
ffffffffc0200f44:	eb85                	bnez	a5,ffffffffc0200f74 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200f46:	60e2                	ld	ra,24(sp)
ffffffffc0200f48:	6442                	ld	s0,16(sp)
ffffffffc0200f4a:	64a2                	ld	s1,8(sp)
ffffffffc0200f4c:	6902                	ld	s2,0(sp)
ffffffffc0200f4e:	6105                	addi	sp,sp,32
ffffffffc0200f50:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200f52:	cb5ff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0200f56:	bff1                	j	ffffffffc0200f32 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200f58:	0006c863          	bltz	a3,ffffffffc0200f68 <trap+0x66>
}
ffffffffc0200f5c:	6442                	ld	s0,16(sp)
ffffffffc0200f5e:	60e2                	ld	ra,24(sp)
ffffffffc0200f60:	64a2                	ld	s1,8(sp)
ffffffffc0200f62:	6902                	ld	s2,0(sp)
ffffffffc0200f64:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200f66:	bb15                	j	ffffffffc0200c9a <exception_handler>
}
ffffffffc0200f68:	6442                	ld	s0,16(sp)
ffffffffc0200f6a:	60e2                	ld	ra,24(sp)
ffffffffc0200f6c:	64a2                	ld	s1,8(sp)
ffffffffc0200f6e:	6902                	ld	s2,0(sp)
ffffffffc0200f70:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200f72:	b951                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0200f74:	6442                	ld	s0,16(sp)
ffffffffc0200f76:	60e2                	ld	ra,24(sp)
ffffffffc0200f78:	64a2                	ld	s1,8(sp)
ffffffffc0200f7a:	6902                	ld	s2,0(sp)
ffffffffc0200f7c:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200f7e:	2720406f          	j	ffffffffc02051f0 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200f82:	555d                	li	a0,-9
ffffffffc0200f84:	5b2030ef          	jal	ra,ffffffffc0204536 <do_exit>
            if (current->need_resched)
ffffffffc0200f88:	601c                	ld	a5,0(s0)
ffffffffc0200f8a:	bf65                	j	ffffffffc0200f42 <trap+0x40>

ffffffffc0200f8c <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200f8c:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200f90:	00011463          	bnez	sp,ffffffffc0200f98 <__alltraps+0xc>
ffffffffc0200f94:	14002173          	csrr	sp,sscratch
ffffffffc0200f98:	712d                	addi	sp,sp,-288
ffffffffc0200f9a:	e002                	sd	zero,0(sp)
ffffffffc0200f9c:	e406                	sd	ra,8(sp)
ffffffffc0200f9e:	ec0e                	sd	gp,24(sp)
ffffffffc0200fa0:	f012                	sd	tp,32(sp)
ffffffffc0200fa2:	f416                	sd	t0,40(sp)
ffffffffc0200fa4:	f81a                	sd	t1,48(sp)
ffffffffc0200fa6:	fc1e                	sd	t2,56(sp)
ffffffffc0200fa8:	e0a2                	sd	s0,64(sp)
ffffffffc0200faa:	e4a6                	sd	s1,72(sp)
ffffffffc0200fac:	e8aa                	sd	a0,80(sp)
ffffffffc0200fae:	ecae                	sd	a1,88(sp)
ffffffffc0200fb0:	f0b2                	sd	a2,96(sp)
ffffffffc0200fb2:	f4b6                	sd	a3,104(sp)
ffffffffc0200fb4:	f8ba                	sd	a4,112(sp)
ffffffffc0200fb6:	fcbe                	sd	a5,120(sp)
ffffffffc0200fb8:	e142                	sd	a6,128(sp)
ffffffffc0200fba:	e546                	sd	a7,136(sp)
ffffffffc0200fbc:	e94a                	sd	s2,144(sp)
ffffffffc0200fbe:	ed4e                	sd	s3,152(sp)
ffffffffc0200fc0:	f152                	sd	s4,160(sp)
ffffffffc0200fc2:	f556                	sd	s5,168(sp)
ffffffffc0200fc4:	f95a                	sd	s6,176(sp)
ffffffffc0200fc6:	fd5e                	sd	s7,184(sp)
ffffffffc0200fc8:	e1e2                	sd	s8,192(sp)
ffffffffc0200fca:	e5e6                	sd	s9,200(sp)
ffffffffc0200fcc:	e9ea                	sd	s10,208(sp)
ffffffffc0200fce:	edee                	sd	s11,216(sp)
ffffffffc0200fd0:	f1f2                	sd	t3,224(sp)
ffffffffc0200fd2:	f5f6                	sd	t4,232(sp)
ffffffffc0200fd4:	f9fa                	sd	t5,240(sp)
ffffffffc0200fd6:	fdfe                	sd	t6,248(sp)
ffffffffc0200fd8:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200fdc:	100024f3          	csrr	s1,sstatus
ffffffffc0200fe0:	14102973          	csrr	s2,sepc
ffffffffc0200fe4:	143029f3          	csrr	s3,stval
ffffffffc0200fe8:	14202a73          	csrr	s4,scause
ffffffffc0200fec:	e822                	sd	s0,16(sp)
ffffffffc0200fee:	e226                	sd	s1,256(sp)
ffffffffc0200ff0:	e64a                	sd	s2,264(sp)
ffffffffc0200ff2:	ea4e                	sd	s3,272(sp)
ffffffffc0200ff4:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200ff6:	850a                	mv	a0,sp
    jal trap
ffffffffc0200ff8:	f0bff0ef          	jal	ra,ffffffffc0200f02 <trap>

ffffffffc0200ffc <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200ffc:	6492                	ld	s1,256(sp)
ffffffffc0200ffe:	6932                	ld	s2,264(sp)
ffffffffc0201000:	1004f413          	andi	s0,s1,256
ffffffffc0201004:	e401                	bnez	s0,ffffffffc020100c <__trapret+0x10>
ffffffffc0201006:	1200                	addi	s0,sp,288
ffffffffc0201008:	14041073          	csrw	sscratch,s0
ffffffffc020100c:	10049073          	csrw	sstatus,s1
ffffffffc0201010:	14191073          	csrw	sepc,s2
ffffffffc0201014:	60a2                	ld	ra,8(sp)
ffffffffc0201016:	61e2                	ld	gp,24(sp)
ffffffffc0201018:	7202                	ld	tp,32(sp)
ffffffffc020101a:	72a2                	ld	t0,40(sp)
ffffffffc020101c:	7342                	ld	t1,48(sp)
ffffffffc020101e:	73e2                	ld	t2,56(sp)
ffffffffc0201020:	6406                	ld	s0,64(sp)
ffffffffc0201022:	64a6                	ld	s1,72(sp)
ffffffffc0201024:	6546                	ld	a0,80(sp)
ffffffffc0201026:	65e6                	ld	a1,88(sp)
ffffffffc0201028:	7606                	ld	a2,96(sp)
ffffffffc020102a:	76a6                	ld	a3,104(sp)
ffffffffc020102c:	7746                	ld	a4,112(sp)
ffffffffc020102e:	77e6                	ld	a5,120(sp)
ffffffffc0201030:	680a                	ld	a6,128(sp)
ffffffffc0201032:	68aa                	ld	a7,136(sp)
ffffffffc0201034:	694a                	ld	s2,144(sp)
ffffffffc0201036:	69ea                	ld	s3,152(sp)
ffffffffc0201038:	7a0a                	ld	s4,160(sp)
ffffffffc020103a:	7aaa                	ld	s5,168(sp)
ffffffffc020103c:	7b4a                	ld	s6,176(sp)
ffffffffc020103e:	7bea                	ld	s7,184(sp)
ffffffffc0201040:	6c0e                	ld	s8,192(sp)
ffffffffc0201042:	6cae                	ld	s9,200(sp)
ffffffffc0201044:	6d4e                	ld	s10,208(sp)
ffffffffc0201046:	6dee                	ld	s11,216(sp)
ffffffffc0201048:	7e0e                	ld	t3,224(sp)
ffffffffc020104a:	7eae                	ld	t4,232(sp)
ffffffffc020104c:	7f4e                	ld	t5,240(sp)
ffffffffc020104e:	7fee                	ld	t6,248(sp)
ffffffffc0201050:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0201052:	10200073          	sret

ffffffffc0201056 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0201056:	812a                	mv	sp,a0
    j __trapret
ffffffffc0201058:	b755                	j	ffffffffc0200ffc <__trapret>

ffffffffc020105a <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc020105a:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc8>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc020105e:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0201062:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0201066:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc020106a:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc020106e:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0201072:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0201076:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc020107a:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc020107e:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0201080:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0201082:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0201084:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0201086:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0201088:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc020108a:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc020108c:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc020108e:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0201090:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0201092:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0201094:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0201096:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0201098:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc020109a:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc020109c:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc020109e:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc02010a0:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc02010a2:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc02010a4:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc02010a6:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc02010a8:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc02010aa:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc02010ac:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc02010ae:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc02010b0:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc02010b2:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc02010b4:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc02010b6:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc02010b8:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc02010ba:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc02010bc:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc02010be:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc02010c0:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc02010c2:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc02010c4:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc02010c6:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc02010c8:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc02010ca:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc02010cc:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc02010ce:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc02010d0:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc02010d2:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc02010d4:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc02010d6:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc02010d8:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc02010da:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc02010dc:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc02010de:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc02010e0:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc02010e2:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc02010e4:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc02010e6:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc02010e8:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc02010ea:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc02010ec:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc02010ee:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc02010f0:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc02010f2:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc02010f4:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc02010f6:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc02010f8:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc02010fa:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc02010fc:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc02010fe:	812e                	mv	sp,a1
ffffffffc0201100:	bdf5                	j	ffffffffc0200ffc <__trapret>

ffffffffc0201102 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0201102:	000a5797          	auipc	a5,0xa5
ffffffffc0201106:	56678793          	addi	a5,a5,1382 # ffffffffc02a6668 <free_area>
ffffffffc020110a:	e79c                	sd	a5,8(a5)
ffffffffc020110c:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc020110e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0201112:	8082                	ret

ffffffffc0201114 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0201114:	000a5517          	auipc	a0,0xa5
ffffffffc0201118:	56456503          	lwu	a0,1380(a0) # ffffffffc02a6678 <free_area+0x10>
ffffffffc020111c:	8082                	ret

ffffffffc020111e <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc020111e:	715d                	addi	sp,sp,-80
ffffffffc0201120:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0201122:	000a5417          	auipc	s0,0xa5
ffffffffc0201126:	54640413          	addi	s0,s0,1350 # ffffffffc02a6668 <free_area>
ffffffffc020112a:	641c                	ld	a5,8(s0)
ffffffffc020112c:	e486                	sd	ra,72(sp)
ffffffffc020112e:	fc26                	sd	s1,56(sp)
ffffffffc0201130:	f84a                	sd	s2,48(sp)
ffffffffc0201132:	f44e                	sd	s3,40(sp)
ffffffffc0201134:	f052                	sd	s4,32(sp)
ffffffffc0201136:	ec56                	sd	s5,24(sp)
ffffffffc0201138:	e85a                	sd	s6,16(sp)
ffffffffc020113a:	e45e                	sd	s7,8(sp)
ffffffffc020113c:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020113e:	2a878d63          	beq	a5,s0,ffffffffc02013f8 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0201142:	4481                	li	s1,0
ffffffffc0201144:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201146:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020114a:	8b09                	andi	a4,a4,2
ffffffffc020114c:	2a070a63          	beqz	a4,ffffffffc0201400 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0201150:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201154:	679c                	ld	a5,8(a5)
ffffffffc0201156:	2905                	addiw	s2,s2,1
ffffffffc0201158:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc020115a:	fe8796e3          	bne	a5,s0,ffffffffc0201146 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc020115e:	89a6                	mv	s3,s1
ffffffffc0201160:	6df000ef          	jal	ra,ffffffffc020203e <nr_free_pages>
ffffffffc0201164:	6f351e63          	bne	a0,s3,ffffffffc0201860 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201168:	4505                	li	a0,1
ffffffffc020116a:	657000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc020116e:	8aaa                	mv	s5,a0
ffffffffc0201170:	42050863          	beqz	a0,ffffffffc02015a0 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201174:	4505                	li	a0,1
ffffffffc0201176:	64b000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc020117a:	89aa                	mv	s3,a0
ffffffffc020117c:	70050263          	beqz	a0,ffffffffc0201880 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201180:	4505                	li	a0,1
ffffffffc0201182:	63f000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc0201186:	8a2a                	mv	s4,a0
ffffffffc0201188:	48050c63          	beqz	a0,ffffffffc0201620 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020118c:	293a8a63          	beq	s5,s3,ffffffffc0201420 <default_check+0x302>
ffffffffc0201190:	28aa8863          	beq	s5,a0,ffffffffc0201420 <default_check+0x302>
ffffffffc0201194:	28a98663          	beq	s3,a0,ffffffffc0201420 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201198:	000aa783          	lw	a5,0(s5)
ffffffffc020119c:	2a079263          	bnez	a5,ffffffffc0201440 <default_check+0x322>
ffffffffc02011a0:	0009a783          	lw	a5,0(s3)
ffffffffc02011a4:	28079e63          	bnez	a5,ffffffffc0201440 <default_check+0x322>
ffffffffc02011a8:	411c                	lw	a5,0(a0)
ffffffffc02011aa:	28079b63          	bnez	a5,ffffffffc0201440 <default_check+0x322>
    return page - pages + nbase;
ffffffffc02011ae:	000a9797          	auipc	a5,0xa9
ffffffffc02011b2:	52a7b783          	ld	a5,1322(a5) # ffffffffc02aa6d8 <pages>
ffffffffc02011b6:	40fa8733          	sub	a4,s5,a5
ffffffffc02011ba:	00006617          	auipc	a2,0x6
ffffffffc02011be:	79663603          	ld	a2,1942(a2) # ffffffffc0207950 <nbase>
ffffffffc02011c2:	8719                	srai	a4,a4,0x6
ffffffffc02011c4:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02011c6:	000a9697          	auipc	a3,0xa9
ffffffffc02011ca:	50a6b683          	ld	a3,1290(a3) # ffffffffc02aa6d0 <npage>
ffffffffc02011ce:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02011d0:	0732                	slli	a4,a4,0xc
ffffffffc02011d2:	28d77763          	bgeu	a4,a3,ffffffffc0201460 <default_check+0x342>
    return page - pages + nbase;
ffffffffc02011d6:	40f98733          	sub	a4,s3,a5
ffffffffc02011da:	8719                	srai	a4,a4,0x6
ffffffffc02011dc:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02011de:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02011e0:	4cd77063          	bgeu	a4,a3,ffffffffc02016a0 <default_check+0x582>
    return page - pages + nbase;
ffffffffc02011e4:	40f507b3          	sub	a5,a0,a5
ffffffffc02011e8:	8799                	srai	a5,a5,0x6
ffffffffc02011ea:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02011ec:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02011ee:	30d7f963          	bgeu	a5,a3,ffffffffc0201500 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc02011f2:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02011f4:	00043c03          	ld	s8,0(s0)
ffffffffc02011f8:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02011fc:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0201200:	e400                	sd	s0,8(s0)
ffffffffc0201202:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0201204:	000a5797          	auipc	a5,0xa5
ffffffffc0201208:	4607aa23          	sw	zero,1140(a5) # ffffffffc02a6678 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc020120c:	5b5000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc0201210:	2c051863          	bnez	a0,ffffffffc02014e0 <default_check+0x3c2>
    free_page(p0);
ffffffffc0201214:	4585                	li	a1,1
ffffffffc0201216:	8556                	mv	a0,s5
ffffffffc0201218:	5e7000ef          	jal	ra,ffffffffc0201ffe <free_pages>
    free_page(p1);
ffffffffc020121c:	4585                	li	a1,1
ffffffffc020121e:	854e                	mv	a0,s3
ffffffffc0201220:	5df000ef          	jal	ra,ffffffffc0201ffe <free_pages>
    free_page(p2);
ffffffffc0201224:	4585                	li	a1,1
ffffffffc0201226:	8552                	mv	a0,s4
ffffffffc0201228:	5d7000ef          	jal	ra,ffffffffc0201ffe <free_pages>
    assert(nr_free == 3);
ffffffffc020122c:	4818                	lw	a4,16(s0)
ffffffffc020122e:	478d                	li	a5,3
ffffffffc0201230:	28f71863          	bne	a4,a5,ffffffffc02014c0 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201234:	4505                	li	a0,1
ffffffffc0201236:	58b000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc020123a:	89aa                	mv	s3,a0
ffffffffc020123c:	26050263          	beqz	a0,ffffffffc02014a0 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201240:	4505                	li	a0,1
ffffffffc0201242:	57f000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc0201246:	8aaa                	mv	s5,a0
ffffffffc0201248:	3a050c63          	beqz	a0,ffffffffc0201600 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020124c:	4505                	li	a0,1
ffffffffc020124e:	573000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc0201252:	8a2a                	mv	s4,a0
ffffffffc0201254:	38050663          	beqz	a0,ffffffffc02015e0 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0201258:	4505                	li	a0,1
ffffffffc020125a:	567000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc020125e:	36051163          	bnez	a0,ffffffffc02015c0 <default_check+0x4a2>
    free_page(p0);
ffffffffc0201262:	4585                	li	a1,1
ffffffffc0201264:	854e                	mv	a0,s3
ffffffffc0201266:	599000ef          	jal	ra,ffffffffc0201ffe <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020126a:	641c                	ld	a5,8(s0)
ffffffffc020126c:	20878a63          	beq	a5,s0,ffffffffc0201480 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0201270:	4505                	li	a0,1
ffffffffc0201272:	54f000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc0201276:	30a99563          	bne	s3,a0,ffffffffc0201580 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc020127a:	4505                	li	a0,1
ffffffffc020127c:	545000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc0201280:	2e051063          	bnez	a0,ffffffffc0201560 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0201284:	481c                	lw	a5,16(s0)
ffffffffc0201286:	2a079d63          	bnez	a5,ffffffffc0201540 <default_check+0x422>
    free_page(p);
ffffffffc020128a:	854e                	mv	a0,s3
ffffffffc020128c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020128e:	01843023          	sd	s8,0(s0)
ffffffffc0201292:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201296:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc020129a:	565000ef          	jal	ra,ffffffffc0201ffe <free_pages>
    free_page(p1);
ffffffffc020129e:	4585                	li	a1,1
ffffffffc02012a0:	8556                	mv	a0,s5
ffffffffc02012a2:	55d000ef          	jal	ra,ffffffffc0201ffe <free_pages>
    free_page(p2);
ffffffffc02012a6:	4585                	li	a1,1
ffffffffc02012a8:	8552                	mv	a0,s4
ffffffffc02012aa:	555000ef          	jal	ra,ffffffffc0201ffe <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02012ae:	4515                	li	a0,5
ffffffffc02012b0:	511000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc02012b4:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02012b6:	26050563          	beqz	a0,ffffffffc0201520 <default_check+0x402>
ffffffffc02012ba:	651c                	ld	a5,8(a0)
ffffffffc02012bc:	8385                	srli	a5,a5,0x1
ffffffffc02012be:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc02012c0:	54079063          	bnez	a5,ffffffffc0201800 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02012c4:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02012c6:	00043b03          	ld	s6,0(s0)
ffffffffc02012ca:	00843a83          	ld	s5,8(s0)
ffffffffc02012ce:	e000                	sd	s0,0(s0)
ffffffffc02012d0:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02012d2:	4ef000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc02012d6:	50051563          	bnez	a0,ffffffffc02017e0 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02012da:	08098a13          	addi	s4,s3,128
ffffffffc02012de:	8552                	mv	a0,s4
ffffffffc02012e0:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02012e2:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02012e6:	000a5797          	auipc	a5,0xa5
ffffffffc02012ea:	3807a923          	sw	zero,914(a5) # ffffffffc02a6678 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02012ee:	511000ef          	jal	ra,ffffffffc0201ffe <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02012f2:	4511                	li	a0,4
ffffffffc02012f4:	4cd000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc02012f8:	4c051463          	bnez	a0,ffffffffc02017c0 <default_check+0x6a2>
ffffffffc02012fc:	0889b783          	ld	a5,136(s3)
ffffffffc0201300:	8385                	srli	a5,a5,0x1
ffffffffc0201302:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201304:	48078e63          	beqz	a5,ffffffffc02017a0 <default_check+0x682>
ffffffffc0201308:	0909a703          	lw	a4,144(s3)
ffffffffc020130c:	478d                	li	a5,3
ffffffffc020130e:	48f71963          	bne	a4,a5,ffffffffc02017a0 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201312:	450d                	li	a0,3
ffffffffc0201314:	4ad000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc0201318:	8c2a                	mv	s8,a0
ffffffffc020131a:	46050363          	beqz	a0,ffffffffc0201780 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc020131e:	4505                	li	a0,1
ffffffffc0201320:	4a1000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc0201324:	42051e63          	bnez	a0,ffffffffc0201760 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201328:	418a1c63          	bne	s4,s8,ffffffffc0201740 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc020132c:	4585                	li	a1,1
ffffffffc020132e:	854e                	mv	a0,s3
ffffffffc0201330:	4cf000ef          	jal	ra,ffffffffc0201ffe <free_pages>
    free_pages(p1, 3);
ffffffffc0201334:	458d                	li	a1,3
ffffffffc0201336:	8552                	mv	a0,s4
ffffffffc0201338:	4c7000ef          	jal	ra,ffffffffc0201ffe <free_pages>
ffffffffc020133c:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201340:	04098c13          	addi	s8,s3,64
ffffffffc0201344:	8385                	srli	a5,a5,0x1
ffffffffc0201346:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201348:	3c078c63          	beqz	a5,ffffffffc0201720 <default_check+0x602>
ffffffffc020134c:	0109a703          	lw	a4,16(s3)
ffffffffc0201350:	4785                	li	a5,1
ffffffffc0201352:	3cf71763          	bne	a4,a5,ffffffffc0201720 <default_check+0x602>
ffffffffc0201356:	008a3783          	ld	a5,8(s4)
ffffffffc020135a:	8385                	srli	a5,a5,0x1
ffffffffc020135c:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020135e:	3a078163          	beqz	a5,ffffffffc0201700 <default_check+0x5e2>
ffffffffc0201362:	010a2703          	lw	a4,16(s4)
ffffffffc0201366:	478d                	li	a5,3
ffffffffc0201368:	38f71c63          	bne	a4,a5,ffffffffc0201700 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020136c:	4505                	li	a0,1
ffffffffc020136e:	453000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc0201372:	36a99763          	bne	s3,a0,ffffffffc02016e0 <default_check+0x5c2>
    free_page(p0);
ffffffffc0201376:	4585                	li	a1,1
ffffffffc0201378:	487000ef          	jal	ra,ffffffffc0201ffe <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020137c:	4509                	li	a0,2
ffffffffc020137e:	443000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc0201382:	32aa1f63          	bne	s4,a0,ffffffffc02016c0 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0201386:	4589                	li	a1,2
ffffffffc0201388:	477000ef          	jal	ra,ffffffffc0201ffe <free_pages>
    free_page(p2);
ffffffffc020138c:	4585                	li	a1,1
ffffffffc020138e:	8562                	mv	a0,s8
ffffffffc0201390:	46f000ef          	jal	ra,ffffffffc0201ffe <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201394:	4515                	li	a0,5
ffffffffc0201396:	42b000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc020139a:	89aa                	mv	s3,a0
ffffffffc020139c:	48050263          	beqz	a0,ffffffffc0201820 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc02013a0:	4505                	li	a0,1
ffffffffc02013a2:	41f000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc02013a6:	2c051d63          	bnez	a0,ffffffffc0201680 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc02013aa:	481c                	lw	a5,16(s0)
ffffffffc02013ac:	2a079a63          	bnez	a5,ffffffffc0201660 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02013b0:	4595                	li	a1,5
ffffffffc02013b2:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02013b4:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02013b8:	01643023          	sd	s6,0(s0)
ffffffffc02013bc:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02013c0:	43f000ef          	jal	ra,ffffffffc0201ffe <free_pages>
    return listelm->next;
ffffffffc02013c4:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02013c6:	00878963          	beq	a5,s0,ffffffffc02013d8 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02013ca:	ff87a703          	lw	a4,-8(a5)
ffffffffc02013ce:	679c                	ld	a5,8(a5)
ffffffffc02013d0:	397d                	addiw	s2,s2,-1
ffffffffc02013d2:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02013d4:	fe879be3          	bne	a5,s0,ffffffffc02013ca <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02013d8:	26091463          	bnez	s2,ffffffffc0201640 <default_check+0x522>
    assert(total == 0);
ffffffffc02013dc:	46049263          	bnez	s1,ffffffffc0201840 <default_check+0x722>
}
ffffffffc02013e0:	60a6                	ld	ra,72(sp)
ffffffffc02013e2:	6406                	ld	s0,64(sp)
ffffffffc02013e4:	74e2                	ld	s1,56(sp)
ffffffffc02013e6:	7942                	ld	s2,48(sp)
ffffffffc02013e8:	79a2                	ld	s3,40(sp)
ffffffffc02013ea:	7a02                	ld	s4,32(sp)
ffffffffc02013ec:	6ae2                	ld	s5,24(sp)
ffffffffc02013ee:	6b42                	ld	s6,16(sp)
ffffffffc02013f0:	6ba2                	ld	s7,8(sp)
ffffffffc02013f2:	6c02                	ld	s8,0(sp)
ffffffffc02013f4:	6161                	addi	sp,sp,80
ffffffffc02013f6:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02013f8:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02013fa:	4481                	li	s1,0
ffffffffc02013fc:	4901                	li	s2,0
ffffffffc02013fe:	b38d                	j	ffffffffc0201160 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201400:	00005697          	auipc	a3,0x5
ffffffffc0201404:	ee068693          	addi	a3,a3,-288 # ffffffffc02062e0 <commands+0x848>
ffffffffc0201408:	00005617          	auipc	a2,0x5
ffffffffc020140c:	ee860613          	addi	a2,a2,-280 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201410:	11000593          	li	a1,272
ffffffffc0201414:	00005517          	auipc	a0,0x5
ffffffffc0201418:	ef450513          	addi	a0,a0,-268 # ffffffffc0206308 <commands+0x870>
ffffffffc020141c:	872ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201420:	00005697          	auipc	a3,0x5
ffffffffc0201424:	f8068693          	addi	a3,a3,-128 # ffffffffc02063a0 <commands+0x908>
ffffffffc0201428:	00005617          	auipc	a2,0x5
ffffffffc020142c:	ec860613          	addi	a2,a2,-312 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201430:	0db00593          	li	a1,219
ffffffffc0201434:	00005517          	auipc	a0,0x5
ffffffffc0201438:	ed450513          	addi	a0,a0,-300 # ffffffffc0206308 <commands+0x870>
ffffffffc020143c:	852ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201440:	00005697          	auipc	a3,0x5
ffffffffc0201444:	f8868693          	addi	a3,a3,-120 # ffffffffc02063c8 <commands+0x930>
ffffffffc0201448:	00005617          	auipc	a2,0x5
ffffffffc020144c:	ea860613          	addi	a2,a2,-344 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201450:	0dc00593          	li	a1,220
ffffffffc0201454:	00005517          	auipc	a0,0x5
ffffffffc0201458:	eb450513          	addi	a0,a0,-332 # ffffffffc0206308 <commands+0x870>
ffffffffc020145c:	832ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201460:	00005697          	auipc	a3,0x5
ffffffffc0201464:	fa868693          	addi	a3,a3,-88 # ffffffffc0206408 <commands+0x970>
ffffffffc0201468:	00005617          	auipc	a2,0x5
ffffffffc020146c:	e8860613          	addi	a2,a2,-376 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201470:	0de00593          	li	a1,222
ffffffffc0201474:	00005517          	auipc	a0,0x5
ffffffffc0201478:	e9450513          	addi	a0,a0,-364 # ffffffffc0206308 <commands+0x870>
ffffffffc020147c:	812ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201480:	00005697          	auipc	a3,0x5
ffffffffc0201484:	01068693          	addi	a3,a3,16 # ffffffffc0206490 <commands+0x9f8>
ffffffffc0201488:	00005617          	auipc	a2,0x5
ffffffffc020148c:	e6860613          	addi	a2,a2,-408 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201490:	0f700593          	li	a1,247
ffffffffc0201494:	00005517          	auipc	a0,0x5
ffffffffc0201498:	e7450513          	addi	a0,a0,-396 # ffffffffc0206308 <commands+0x870>
ffffffffc020149c:	ff3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02014a0:	00005697          	auipc	a3,0x5
ffffffffc02014a4:	ea068693          	addi	a3,a3,-352 # ffffffffc0206340 <commands+0x8a8>
ffffffffc02014a8:	00005617          	auipc	a2,0x5
ffffffffc02014ac:	e4860613          	addi	a2,a2,-440 # ffffffffc02062f0 <commands+0x858>
ffffffffc02014b0:	0f000593          	li	a1,240
ffffffffc02014b4:	00005517          	auipc	a0,0x5
ffffffffc02014b8:	e5450513          	addi	a0,a0,-428 # ffffffffc0206308 <commands+0x870>
ffffffffc02014bc:	fd3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc02014c0:	00005697          	auipc	a3,0x5
ffffffffc02014c4:	fc068693          	addi	a3,a3,-64 # ffffffffc0206480 <commands+0x9e8>
ffffffffc02014c8:	00005617          	auipc	a2,0x5
ffffffffc02014cc:	e2860613          	addi	a2,a2,-472 # ffffffffc02062f0 <commands+0x858>
ffffffffc02014d0:	0ee00593          	li	a1,238
ffffffffc02014d4:	00005517          	auipc	a0,0x5
ffffffffc02014d8:	e3450513          	addi	a0,a0,-460 # ffffffffc0206308 <commands+0x870>
ffffffffc02014dc:	fb3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014e0:	00005697          	auipc	a3,0x5
ffffffffc02014e4:	f8868693          	addi	a3,a3,-120 # ffffffffc0206468 <commands+0x9d0>
ffffffffc02014e8:	00005617          	auipc	a2,0x5
ffffffffc02014ec:	e0860613          	addi	a2,a2,-504 # ffffffffc02062f0 <commands+0x858>
ffffffffc02014f0:	0e900593          	li	a1,233
ffffffffc02014f4:	00005517          	auipc	a0,0x5
ffffffffc02014f8:	e1450513          	addi	a0,a0,-492 # ffffffffc0206308 <commands+0x870>
ffffffffc02014fc:	f93fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201500:	00005697          	auipc	a3,0x5
ffffffffc0201504:	f4868693          	addi	a3,a3,-184 # ffffffffc0206448 <commands+0x9b0>
ffffffffc0201508:	00005617          	auipc	a2,0x5
ffffffffc020150c:	de860613          	addi	a2,a2,-536 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201510:	0e000593          	li	a1,224
ffffffffc0201514:	00005517          	auipc	a0,0x5
ffffffffc0201518:	df450513          	addi	a0,a0,-524 # ffffffffc0206308 <commands+0x870>
ffffffffc020151c:	f73fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc0201520:	00005697          	auipc	a3,0x5
ffffffffc0201524:	fb868693          	addi	a3,a3,-72 # ffffffffc02064d8 <commands+0xa40>
ffffffffc0201528:	00005617          	auipc	a2,0x5
ffffffffc020152c:	dc860613          	addi	a2,a2,-568 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201530:	11800593          	li	a1,280
ffffffffc0201534:	00005517          	auipc	a0,0x5
ffffffffc0201538:	dd450513          	addi	a0,a0,-556 # ffffffffc0206308 <commands+0x870>
ffffffffc020153c:	f53fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc0201540:	00005697          	auipc	a3,0x5
ffffffffc0201544:	f8868693          	addi	a3,a3,-120 # ffffffffc02064c8 <commands+0xa30>
ffffffffc0201548:	00005617          	auipc	a2,0x5
ffffffffc020154c:	da860613          	addi	a2,a2,-600 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201550:	0fd00593          	li	a1,253
ffffffffc0201554:	00005517          	auipc	a0,0x5
ffffffffc0201558:	db450513          	addi	a0,a0,-588 # ffffffffc0206308 <commands+0x870>
ffffffffc020155c:	f33fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201560:	00005697          	auipc	a3,0x5
ffffffffc0201564:	f0868693          	addi	a3,a3,-248 # ffffffffc0206468 <commands+0x9d0>
ffffffffc0201568:	00005617          	auipc	a2,0x5
ffffffffc020156c:	d8860613          	addi	a2,a2,-632 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201570:	0fb00593          	li	a1,251
ffffffffc0201574:	00005517          	auipc	a0,0x5
ffffffffc0201578:	d9450513          	addi	a0,a0,-620 # ffffffffc0206308 <commands+0x870>
ffffffffc020157c:	f13fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201580:	00005697          	auipc	a3,0x5
ffffffffc0201584:	f2868693          	addi	a3,a3,-216 # ffffffffc02064a8 <commands+0xa10>
ffffffffc0201588:	00005617          	auipc	a2,0x5
ffffffffc020158c:	d6860613          	addi	a2,a2,-664 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201590:	0fa00593          	li	a1,250
ffffffffc0201594:	00005517          	auipc	a0,0x5
ffffffffc0201598:	d7450513          	addi	a0,a0,-652 # ffffffffc0206308 <commands+0x870>
ffffffffc020159c:	ef3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02015a0:	00005697          	auipc	a3,0x5
ffffffffc02015a4:	da068693          	addi	a3,a3,-608 # ffffffffc0206340 <commands+0x8a8>
ffffffffc02015a8:	00005617          	auipc	a2,0x5
ffffffffc02015ac:	d4860613          	addi	a2,a2,-696 # ffffffffc02062f0 <commands+0x858>
ffffffffc02015b0:	0d700593          	li	a1,215
ffffffffc02015b4:	00005517          	auipc	a0,0x5
ffffffffc02015b8:	d5450513          	addi	a0,a0,-684 # ffffffffc0206308 <commands+0x870>
ffffffffc02015bc:	ed3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015c0:	00005697          	auipc	a3,0x5
ffffffffc02015c4:	ea868693          	addi	a3,a3,-344 # ffffffffc0206468 <commands+0x9d0>
ffffffffc02015c8:	00005617          	auipc	a2,0x5
ffffffffc02015cc:	d2860613          	addi	a2,a2,-728 # ffffffffc02062f0 <commands+0x858>
ffffffffc02015d0:	0f400593          	li	a1,244
ffffffffc02015d4:	00005517          	auipc	a0,0x5
ffffffffc02015d8:	d3450513          	addi	a0,a0,-716 # ffffffffc0206308 <commands+0x870>
ffffffffc02015dc:	eb3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02015e0:	00005697          	auipc	a3,0x5
ffffffffc02015e4:	da068693          	addi	a3,a3,-608 # ffffffffc0206380 <commands+0x8e8>
ffffffffc02015e8:	00005617          	auipc	a2,0x5
ffffffffc02015ec:	d0860613          	addi	a2,a2,-760 # ffffffffc02062f0 <commands+0x858>
ffffffffc02015f0:	0f200593          	li	a1,242
ffffffffc02015f4:	00005517          	auipc	a0,0x5
ffffffffc02015f8:	d1450513          	addi	a0,a0,-748 # ffffffffc0206308 <commands+0x870>
ffffffffc02015fc:	e93fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201600:	00005697          	auipc	a3,0x5
ffffffffc0201604:	d6068693          	addi	a3,a3,-672 # ffffffffc0206360 <commands+0x8c8>
ffffffffc0201608:	00005617          	auipc	a2,0x5
ffffffffc020160c:	ce860613          	addi	a2,a2,-792 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201610:	0f100593          	li	a1,241
ffffffffc0201614:	00005517          	auipc	a0,0x5
ffffffffc0201618:	cf450513          	addi	a0,a0,-780 # ffffffffc0206308 <commands+0x870>
ffffffffc020161c:	e73fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201620:	00005697          	auipc	a3,0x5
ffffffffc0201624:	d6068693          	addi	a3,a3,-672 # ffffffffc0206380 <commands+0x8e8>
ffffffffc0201628:	00005617          	auipc	a2,0x5
ffffffffc020162c:	cc860613          	addi	a2,a2,-824 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201630:	0d900593          	li	a1,217
ffffffffc0201634:	00005517          	auipc	a0,0x5
ffffffffc0201638:	cd450513          	addi	a0,a0,-812 # ffffffffc0206308 <commands+0x870>
ffffffffc020163c:	e53fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc0201640:	00005697          	auipc	a3,0x5
ffffffffc0201644:	fe868693          	addi	a3,a3,-24 # ffffffffc0206628 <commands+0xb90>
ffffffffc0201648:	00005617          	auipc	a2,0x5
ffffffffc020164c:	ca860613          	addi	a2,a2,-856 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201650:	14600593          	li	a1,326
ffffffffc0201654:	00005517          	auipc	a0,0x5
ffffffffc0201658:	cb450513          	addi	a0,a0,-844 # ffffffffc0206308 <commands+0x870>
ffffffffc020165c:	e33fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc0201660:	00005697          	auipc	a3,0x5
ffffffffc0201664:	e6868693          	addi	a3,a3,-408 # ffffffffc02064c8 <commands+0xa30>
ffffffffc0201668:	00005617          	auipc	a2,0x5
ffffffffc020166c:	c8860613          	addi	a2,a2,-888 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201670:	13a00593          	li	a1,314
ffffffffc0201674:	00005517          	auipc	a0,0x5
ffffffffc0201678:	c9450513          	addi	a0,a0,-876 # ffffffffc0206308 <commands+0x870>
ffffffffc020167c:	e13fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201680:	00005697          	auipc	a3,0x5
ffffffffc0201684:	de868693          	addi	a3,a3,-536 # ffffffffc0206468 <commands+0x9d0>
ffffffffc0201688:	00005617          	auipc	a2,0x5
ffffffffc020168c:	c6860613          	addi	a2,a2,-920 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201690:	13800593          	li	a1,312
ffffffffc0201694:	00005517          	auipc	a0,0x5
ffffffffc0201698:	c7450513          	addi	a0,a0,-908 # ffffffffc0206308 <commands+0x870>
ffffffffc020169c:	df3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02016a0:	00005697          	auipc	a3,0x5
ffffffffc02016a4:	d8868693          	addi	a3,a3,-632 # ffffffffc0206428 <commands+0x990>
ffffffffc02016a8:	00005617          	auipc	a2,0x5
ffffffffc02016ac:	c4860613          	addi	a2,a2,-952 # ffffffffc02062f0 <commands+0x858>
ffffffffc02016b0:	0df00593          	li	a1,223
ffffffffc02016b4:	00005517          	auipc	a0,0x5
ffffffffc02016b8:	c5450513          	addi	a0,a0,-940 # ffffffffc0206308 <commands+0x870>
ffffffffc02016bc:	dd3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02016c0:	00005697          	auipc	a3,0x5
ffffffffc02016c4:	f2868693          	addi	a3,a3,-216 # ffffffffc02065e8 <commands+0xb50>
ffffffffc02016c8:	00005617          	auipc	a2,0x5
ffffffffc02016cc:	c2860613          	addi	a2,a2,-984 # ffffffffc02062f0 <commands+0x858>
ffffffffc02016d0:	13200593          	li	a1,306
ffffffffc02016d4:	00005517          	auipc	a0,0x5
ffffffffc02016d8:	c3450513          	addi	a0,a0,-972 # ffffffffc0206308 <commands+0x870>
ffffffffc02016dc:	db3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02016e0:	00005697          	auipc	a3,0x5
ffffffffc02016e4:	ee868693          	addi	a3,a3,-280 # ffffffffc02065c8 <commands+0xb30>
ffffffffc02016e8:	00005617          	auipc	a2,0x5
ffffffffc02016ec:	c0860613          	addi	a2,a2,-1016 # ffffffffc02062f0 <commands+0x858>
ffffffffc02016f0:	13000593          	li	a1,304
ffffffffc02016f4:	00005517          	auipc	a0,0x5
ffffffffc02016f8:	c1450513          	addi	a0,a0,-1004 # ffffffffc0206308 <commands+0x870>
ffffffffc02016fc:	d93fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201700:	00005697          	auipc	a3,0x5
ffffffffc0201704:	ea068693          	addi	a3,a3,-352 # ffffffffc02065a0 <commands+0xb08>
ffffffffc0201708:	00005617          	auipc	a2,0x5
ffffffffc020170c:	be860613          	addi	a2,a2,-1048 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201710:	12e00593          	li	a1,302
ffffffffc0201714:	00005517          	auipc	a0,0x5
ffffffffc0201718:	bf450513          	addi	a0,a0,-1036 # ffffffffc0206308 <commands+0x870>
ffffffffc020171c:	d73fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201720:	00005697          	auipc	a3,0x5
ffffffffc0201724:	e5868693          	addi	a3,a3,-424 # ffffffffc0206578 <commands+0xae0>
ffffffffc0201728:	00005617          	auipc	a2,0x5
ffffffffc020172c:	bc860613          	addi	a2,a2,-1080 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201730:	12d00593          	li	a1,301
ffffffffc0201734:	00005517          	auipc	a0,0x5
ffffffffc0201738:	bd450513          	addi	a0,a0,-1068 # ffffffffc0206308 <commands+0x870>
ffffffffc020173c:	d53fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201740:	00005697          	auipc	a3,0x5
ffffffffc0201744:	e2868693          	addi	a3,a3,-472 # ffffffffc0206568 <commands+0xad0>
ffffffffc0201748:	00005617          	auipc	a2,0x5
ffffffffc020174c:	ba860613          	addi	a2,a2,-1112 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201750:	12800593          	li	a1,296
ffffffffc0201754:	00005517          	auipc	a0,0x5
ffffffffc0201758:	bb450513          	addi	a0,a0,-1100 # ffffffffc0206308 <commands+0x870>
ffffffffc020175c:	d33fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201760:	00005697          	auipc	a3,0x5
ffffffffc0201764:	d0868693          	addi	a3,a3,-760 # ffffffffc0206468 <commands+0x9d0>
ffffffffc0201768:	00005617          	auipc	a2,0x5
ffffffffc020176c:	b8860613          	addi	a2,a2,-1144 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201770:	12700593          	li	a1,295
ffffffffc0201774:	00005517          	auipc	a0,0x5
ffffffffc0201778:	b9450513          	addi	a0,a0,-1132 # ffffffffc0206308 <commands+0x870>
ffffffffc020177c:	d13fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201780:	00005697          	auipc	a3,0x5
ffffffffc0201784:	dc868693          	addi	a3,a3,-568 # ffffffffc0206548 <commands+0xab0>
ffffffffc0201788:	00005617          	auipc	a2,0x5
ffffffffc020178c:	b6860613          	addi	a2,a2,-1176 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201790:	12600593          	li	a1,294
ffffffffc0201794:	00005517          	auipc	a0,0x5
ffffffffc0201798:	b7450513          	addi	a0,a0,-1164 # ffffffffc0206308 <commands+0x870>
ffffffffc020179c:	cf3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02017a0:	00005697          	auipc	a3,0x5
ffffffffc02017a4:	d7868693          	addi	a3,a3,-648 # ffffffffc0206518 <commands+0xa80>
ffffffffc02017a8:	00005617          	auipc	a2,0x5
ffffffffc02017ac:	b4860613          	addi	a2,a2,-1208 # ffffffffc02062f0 <commands+0x858>
ffffffffc02017b0:	12500593          	li	a1,293
ffffffffc02017b4:	00005517          	auipc	a0,0x5
ffffffffc02017b8:	b5450513          	addi	a0,a0,-1196 # ffffffffc0206308 <commands+0x870>
ffffffffc02017bc:	cd3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02017c0:	00005697          	auipc	a3,0x5
ffffffffc02017c4:	d4068693          	addi	a3,a3,-704 # ffffffffc0206500 <commands+0xa68>
ffffffffc02017c8:	00005617          	auipc	a2,0x5
ffffffffc02017cc:	b2860613          	addi	a2,a2,-1240 # ffffffffc02062f0 <commands+0x858>
ffffffffc02017d0:	12400593          	li	a1,292
ffffffffc02017d4:	00005517          	auipc	a0,0x5
ffffffffc02017d8:	b3450513          	addi	a0,a0,-1228 # ffffffffc0206308 <commands+0x870>
ffffffffc02017dc:	cb3fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02017e0:	00005697          	auipc	a3,0x5
ffffffffc02017e4:	c8868693          	addi	a3,a3,-888 # ffffffffc0206468 <commands+0x9d0>
ffffffffc02017e8:	00005617          	auipc	a2,0x5
ffffffffc02017ec:	b0860613          	addi	a2,a2,-1272 # ffffffffc02062f0 <commands+0x858>
ffffffffc02017f0:	11e00593          	li	a1,286
ffffffffc02017f4:	00005517          	auipc	a0,0x5
ffffffffc02017f8:	b1450513          	addi	a0,a0,-1260 # ffffffffc0206308 <commands+0x870>
ffffffffc02017fc:	c93fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc0201800:	00005697          	auipc	a3,0x5
ffffffffc0201804:	ce868693          	addi	a3,a3,-792 # ffffffffc02064e8 <commands+0xa50>
ffffffffc0201808:	00005617          	auipc	a2,0x5
ffffffffc020180c:	ae860613          	addi	a2,a2,-1304 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201810:	11900593          	li	a1,281
ffffffffc0201814:	00005517          	auipc	a0,0x5
ffffffffc0201818:	af450513          	addi	a0,a0,-1292 # ffffffffc0206308 <commands+0x870>
ffffffffc020181c:	c73fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201820:	00005697          	auipc	a3,0x5
ffffffffc0201824:	de868693          	addi	a3,a3,-536 # ffffffffc0206608 <commands+0xb70>
ffffffffc0201828:	00005617          	auipc	a2,0x5
ffffffffc020182c:	ac860613          	addi	a2,a2,-1336 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201830:	13700593          	li	a1,311
ffffffffc0201834:	00005517          	auipc	a0,0x5
ffffffffc0201838:	ad450513          	addi	a0,a0,-1324 # ffffffffc0206308 <commands+0x870>
ffffffffc020183c:	c53fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc0201840:	00005697          	auipc	a3,0x5
ffffffffc0201844:	df868693          	addi	a3,a3,-520 # ffffffffc0206638 <commands+0xba0>
ffffffffc0201848:	00005617          	auipc	a2,0x5
ffffffffc020184c:	aa860613          	addi	a2,a2,-1368 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201850:	14700593          	li	a1,327
ffffffffc0201854:	00005517          	auipc	a0,0x5
ffffffffc0201858:	ab450513          	addi	a0,a0,-1356 # ffffffffc0206308 <commands+0x870>
ffffffffc020185c:	c33fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc0201860:	00005697          	auipc	a3,0x5
ffffffffc0201864:	ac068693          	addi	a3,a3,-1344 # ffffffffc0206320 <commands+0x888>
ffffffffc0201868:	00005617          	auipc	a2,0x5
ffffffffc020186c:	a8860613          	addi	a2,a2,-1400 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201870:	11300593          	li	a1,275
ffffffffc0201874:	00005517          	auipc	a0,0x5
ffffffffc0201878:	a9450513          	addi	a0,a0,-1388 # ffffffffc0206308 <commands+0x870>
ffffffffc020187c:	c13fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201880:	00005697          	auipc	a3,0x5
ffffffffc0201884:	ae068693          	addi	a3,a3,-1312 # ffffffffc0206360 <commands+0x8c8>
ffffffffc0201888:	00005617          	auipc	a2,0x5
ffffffffc020188c:	a6860613          	addi	a2,a2,-1432 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201890:	0d800593          	li	a1,216
ffffffffc0201894:	00005517          	auipc	a0,0x5
ffffffffc0201898:	a7450513          	addi	a0,a0,-1420 # ffffffffc0206308 <commands+0x870>
ffffffffc020189c:	bf3fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02018a0 <default_free_pages>:
{
ffffffffc02018a0:	1141                	addi	sp,sp,-16
ffffffffc02018a2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02018a4:	14058463          	beqz	a1,ffffffffc02019ec <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc02018a8:	00659693          	slli	a3,a1,0x6
ffffffffc02018ac:	96aa                	add	a3,a3,a0
ffffffffc02018ae:	87aa                	mv	a5,a0
ffffffffc02018b0:	02d50263          	beq	a0,a3,ffffffffc02018d4 <default_free_pages+0x34>
ffffffffc02018b4:	6798                	ld	a4,8(a5)
ffffffffc02018b6:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02018b8:	10071a63          	bnez	a4,ffffffffc02019cc <default_free_pages+0x12c>
ffffffffc02018bc:	6798                	ld	a4,8(a5)
ffffffffc02018be:	8b09                	andi	a4,a4,2
ffffffffc02018c0:	10071663          	bnez	a4,ffffffffc02019cc <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc02018c4:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02018c8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02018cc:	04078793          	addi	a5,a5,64
ffffffffc02018d0:	fed792e3          	bne	a5,a3,ffffffffc02018b4 <default_free_pages+0x14>
    base->property = n;
ffffffffc02018d4:	2581                	sext.w	a1,a1
ffffffffc02018d6:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02018d8:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018dc:	4789                	li	a5,2
ffffffffc02018de:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02018e2:	000a5697          	auipc	a3,0xa5
ffffffffc02018e6:	d8668693          	addi	a3,a3,-634 # ffffffffc02a6668 <free_area>
ffffffffc02018ea:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02018ec:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02018ee:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02018f2:	9db9                	addw	a1,a1,a4
ffffffffc02018f4:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02018f6:	0ad78463          	beq	a5,a3,ffffffffc020199e <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc02018fa:	fe878713          	addi	a4,a5,-24
ffffffffc02018fe:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201902:	4581                	li	a1,0
            if (base < page)
ffffffffc0201904:	00e56a63          	bltu	a0,a4,ffffffffc0201918 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201908:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020190a:	04d70c63          	beq	a4,a3,ffffffffc0201962 <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc020190e:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201910:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201914:	fee57ae3          	bgeu	a0,a4,ffffffffc0201908 <default_free_pages+0x68>
ffffffffc0201918:	c199                	beqz	a1,ffffffffc020191e <default_free_pages+0x7e>
ffffffffc020191a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020191e:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201920:	e390                	sd	a2,0(a5)
ffffffffc0201922:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201924:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201926:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc0201928:	00d70d63          	beq	a4,a3,ffffffffc0201942 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc020192c:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201930:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0201934:	02059813          	slli	a6,a1,0x20
ffffffffc0201938:	01a85793          	srli	a5,a6,0x1a
ffffffffc020193c:	97b2                	add	a5,a5,a2
ffffffffc020193e:	02f50c63          	beq	a0,a5,ffffffffc0201976 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0201942:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201944:	00d78c63          	beq	a5,a3,ffffffffc020195c <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201948:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc020194a:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc020194e:	02061593          	slli	a1,a2,0x20
ffffffffc0201952:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201956:	972a                	add	a4,a4,a0
ffffffffc0201958:	04e68a63          	beq	a3,a4,ffffffffc02019ac <default_free_pages+0x10c>
}
ffffffffc020195c:	60a2                	ld	ra,8(sp)
ffffffffc020195e:	0141                	addi	sp,sp,16
ffffffffc0201960:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201962:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201964:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201966:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201968:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc020196a:	02d70763          	beq	a4,a3,ffffffffc0201998 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc020196e:	8832                	mv	a6,a2
ffffffffc0201970:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201972:	87ba                	mv	a5,a4
ffffffffc0201974:	bf71                	j	ffffffffc0201910 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201976:	491c                	lw	a5,16(a0)
ffffffffc0201978:	9dbd                	addw	a1,a1,a5
ffffffffc020197a:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020197e:	57f5                	li	a5,-3
ffffffffc0201980:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201984:	01853803          	ld	a6,24(a0)
ffffffffc0201988:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020198a:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020198c:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201990:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201992:	0105b023          	sd	a6,0(a1)
ffffffffc0201996:	b77d                	j	ffffffffc0201944 <default_free_pages+0xa4>
ffffffffc0201998:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc020199a:	873e                	mv	a4,a5
ffffffffc020199c:	bf41                	j	ffffffffc020192c <default_free_pages+0x8c>
}
ffffffffc020199e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02019a0:	e390                	sd	a2,0(a5)
ffffffffc02019a2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02019a4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02019a6:	ed1c                	sd	a5,24(a0)
ffffffffc02019a8:	0141                	addi	sp,sp,16
ffffffffc02019aa:	8082                	ret
            base->property += p->property;
ffffffffc02019ac:	ff87a703          	lw	a4,-8(a5)
ffffffffc02019b0:	ff078693          	addi	a3,a5,-16
ffffffffc02019b4:	9e39                	addw	a2,a2,a4
ffffffffc02019b6:	c910                	sw	a2,16(a0)
ffffffffc02019b8:	5775                	li	a4,-3
ffffffffc02019ba:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02019be:	6398                	ld	a4,0(a5)
ffffffffc02019c0:	679c                	ld	a5,8(a5)
}
ffffffffc02019c2:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02019c4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02019c6:	e398                	sd	a4,0(a5)
ffffffffc02019c8:	0141                	addi	sp,sp,16
ffffffffc02019ca:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02019cc:	00005697          	auipc	a3,0x5
ffffffffc02019d0:	c8468693          	addi	a3,a3,-892 # ffffffffc0206650 <commands+0xbb8>
ffffffffc02019d4:	00005617          	auipc	a2,0x5
ffffffffc02019d8:	91c60613          	addi	a2,a2,-1764 # ffffffffc02062f0 <commands+0x858>
ffffffffc02019dc:	09400593          	li	a1,148
ffffffffc02019e0:	00005517          	auipc	a0,0x5
ffffffffc02019e4:	92850513          	addi	a0,a0,-1752 # ffffffffc0206308 <commands+0x870>
ffffffffc02019e8:	aa7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc02019ec:	00005697          	auipc	a3,0x5
ffffffffc02019f0:	c5c68693          	addi	a3,a3,-932 # ffffffffc0206648 <commands+0xbb0>
ffffffffc02019f4:	00005617          	auipc	a2,0x5
ffffffffc02019f8:	8fc60613          	addi	a2,a2,-1796 # ffffffffc02062f0 <commands+0x858>
ffffffffc02019fc:	09000593          	li	a1,144
ffffffffc0201a00:	00005517          	auipc	a0,0x5
ffffffffc0201a04:	90850513          	addi	a0,a0,-1784 # ffffffffc0206308 <commands+0x870>
ffffffffc0201a08:	a87fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201a0c <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201a0c:	c941                	beqz	a0,ffffffffc0201a9c <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc0201a0e:	000a5597          	auipc	a1,0xa5
ffffffffc0201a12:	c5a58593          	addi	a1,a1,-934 # ffffffffc02a6668 <free_area>
ffffffffc0201a16:	0105a803          	lw	a6,16(a1)
ffffffffc0201a1a:	872a                	mv	a4,a0
ffffffffc0201a1c:	02081793          	slli	a5,a6,0x20
ffffffffc0201a20:	9381                	srli	a5,a5,0x20
ffffffffc0201a22:	00a7ee63          	bltu	a5,a0,ffffffffc0201a3e <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201a26:	87ae                	mv	a5,a1
ffffffffc0201a28:	a801                	j	ffffffffc0201a38 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0201a2a:	ff87a683          	lw	a3,-8(a5)
ffffffffc0201a2e:	02069613          	slli	a2,a3,0x20
ffffffffc0201a32:	9201                	srli	a2,a2,0x20
ffffffffc0201a34:	00e67763          	bgeu	a2,a4,ffffffffc0201a42 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201a38:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201a3a:	feb798e3          	bne	a5,a1,ffffffffc0201a2a <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201a3e:	4501                	li	a0,0
}
ffffffffc0201a40:	8082                	ret
    return listelm->prev;
ffffffffc0201a42:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201a46:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201a4a:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201a4e:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0201a52:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201a56:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0201a5a:	02c77863          	bgeu	a4,a2,ffffffffc0201a8a <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201a5e:	071a                	slli	a4,a4,0x6
ffffffffc0201a60:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201a62:	41c686bb          	subw	a3,a3,t3
ffffffffc0201a66:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201a68:	00870613          	addi	a2,a4,8
ffffffffc0201a6c:	4689                	li	a3,2
ffffffffc0201a6e:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201a72:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201a76:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201a7a:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201a7e:	e290                	sd	a2,0(a3)
ffffffffc0201a80:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201a84:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201a86:	01173c23          	sd	a7,24(a4)
ffffffffc0201a8a:	41c8083b          	subw	a6,a6,t3
ffffffffc0201a8e:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201a92:	5775                	li	a4,-3
ffffffffc0201a94:	17c1                	addi	a5,a5,-16
ffffffffc0201a96:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201a9a:	8082                	ret
{
ffffffffc0201a9c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201a9e:	00005697          	auipc	a3,0x5
ffffffffc0201aa2:	baa68693          	addi	a3,a3,-1110 # ffffffffc0206648 <commands+0xbb0>
ffffffffc0201aa6:	00005617          	auipc	a2,0x5
ffffffffc0201aaa:	84a60613          	addi	a2,a2,-1974 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201aae:	06c00593          	li	a1,108
ffffffffc0201ab2:	00005517          	auipc	a0,0x5
ffffffffc0201ab6:	85650513          	addi	a0,a0,-1962 # ffffffffc0206308 <commands+0x870>
{
ffffffffc0201aba:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201abc:	9d3fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ac0 <default_init_memmap>:
{
ffffffffc0201ac0:	1141                	addi	sp,sp,-16
ffffffffc0201ac2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201ac4:	c5f1                	beqz	a1,ffffffffc0201b90 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201ac6:	00659693          	slli	a3,a1,0x6
ffffffffc0201aca:	96aa                	add	a3,a3,a0
ffffffffc0201acc:	87aa                	mv	a5,a0
ffffffffc0201ace:	00d50f63          	beq	a0,a3,ffffffffc0201aec <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201ad2:	6798                	ld	a4,8(a5)
ffffffffc0201ad4:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201ad6:	cf49                	beqz	a4,ffffffffc0201b70 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201ad8:	0007a823          	sw	zero,16(a5)
ffffffffc0201adc:	0007b423          	sd	zero,8(a5)
ffffffffc0201ae0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201ae4:	04078793          	addi	a5,a5,64
ffffffffc0201ae8:	fed795e3          	bne	a5,a3,ffffffffc0201ad2 <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201aec:	2581                	sext.w	a1,a1
ffffffffc0201aee:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201af0:	4789                	li	a5,2
ffffffffc0201af2:	00850713          	addi	a4,a0,8
ffffffffc0201af6:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201afa:	000a5697          	auipc	a3,0xa5
ffffffffc0201afe:	b6e68693          	addi	a3,a3,-1170 # ffffffffc02a6668 <free_area>
ffffffffc0201b02:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201b04:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201b06:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201b0a:	9db9                	addw	a1,a1,a4
ffffffffc0201b0c:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201b0e:	04d78a63          	beq	a5,a3,ffffffffc0201b62 <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201b12:	fe878713          	addi	a4,a5,-24
ffffffffc0201b16:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201b1a:	4581                	li	a1,0
            if (base < page)
ffffffffc0201b1c:	00e56a63          	bltu	a0,a4,ffffffffc0201b30 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201b20:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201b22:	02d70263          	beq	a4,a3,ffffffffc0201b46 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0201b26:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201b28:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201b2c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201b20 <default_init_memmap+0x60>
ffffffffc0201b30:	c199                	beqz	a1,ffffffffc0201b36 <default_init_memmap+0x76>
ffffffffc0201b32:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201b36:	6398                	ld	a4,0(a5)
}
ffffffffc0201b38:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201b3a:	e390                	sd	a2,0(a5)
ffffffffc0201b3c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201b3e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201b40:	ed18                	sd	a4,24(a0)
ffffffffc0201b42:	0141                	addi	sp,sp,16
ffffffffc0201b44:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201b46:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201b48:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201b4a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201b4c:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201b4e:	00d70663          	beq	a4,a3,ffffffffc0201b5a <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201b52:	8832                	mv	a6,a2
ffffffffc0201b54:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201b56:	87ba                	mv	a5,a4
ffffffffc0201b58:	bfc1                	j	ffffffffc0201b28 <default_init_memmap+0x68>
}
ffffffffc0201b5a:	60a2                	ld	ra,8(sp)
ffffffffc0201b5c:	e290                	sd	a2,0(a3)
ffffffffc0201b5e:	0141                	addi	sp,sp,16
ffffffffc0201b60:	8082                	ret
ffffffffc0201b62:	60a2                	ld	ra,8(sp)
ffffffffc0201b64:	e390                	sd	a2,0(a5)
ffffffffc0201b66:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201b68:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201b6a:	ed1c                	sd	a5,24(a0)
ffffffffc0201b6c:	0141                	addi	sp,sp,16
ffffffffc0201b6e:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201b70:	00005697          	auipc	a3,0x5
ffffffffc0201b74:	b0868693          	addi	a3,a3,-1272 # ffffffffc0206678 <commands+0xbe0>
ffffffffc0201b78:	00004617          	auipc	a2,0x4
ffffffffc0201b7c:	77860613          	addi	a2,a2,1912 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201b80:	04b00593          	li	a1,75
ffffffffc0201b84:	00004517          	auipc	a0,0x4
ffffffffc0201b88:	78450513          	addi	a0,a0,1924 # ffffffffc0206308 <commands+0x870>
ffffffffc0201b8c:	903fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201b90:	00005697          	auipc	a3,0x5
ffffffffc0201b94:	ab868693          	addi	a3,a3,-1352 # ffffffffc0206648 <commands+0xbb0>
ffffffffc0201b98:	00004617          	auipc	a2,0x4
ffffffffc0201b9c:	75860613          	addi	a2,a2,1880 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201ba0:	04700593          	li	a1,71
ffffffffc0201ba4:	00004517          	auipc	a0,0x4
ffffffffc0201ba8:	76450513          	addi	a0,a0,1892 # ffffffffc0206308 <commands+0x870>
ffffffffc0201bac:	8e3fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201bb0 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201bb0:	c94d                	beqz	a0,ffffffffc0201c62 <slob_free+0xb2>
{
ffffffffc0201bb2:	1141                	addi	sp,sp,-16
ffffffffc0201bb4:	e022                	sd	s0,0(sp)
ffffffffc0201bb6:	e406                	sd	ra,8(sp)
ffffffffc0201bb8:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201bba:	e9c1                	bnez	a1,ffffffffc0201c4a <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bbc:	100027f3          	csrr	a5,sstatus
ffffffffc0201bc0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201bc2:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bc4:	ebd9                	bnez	a5,ffffffffc0201c5a <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201bc6:	000a4617          	auipc	a2,0xa4
ffffffffc0201bca:	69260613          	addi	a2,a2,1682 # ffffffffc02a6258 <slobfree>
ffffffffc0201bce:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201bd0:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201bd2:	679c                	ld	a5,8(a5)
ffffffffc0201bd4:	02877a63          	bgeu	a4,s0,ffffffffc0201c08 <slob_free+0x58>
ffffffffc0201bd8:	00f46463          	bltu	s0,a5,ffffffffc0201be0 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201bdc:	fef76ae3          	bltu	a4,a5,ffffffffc0201bd0 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201be0:	400c                	lw	a1,0(s0)
ffffffffc0201be2:	00459693          	slli	a3,a1,0x4
ffffffffc0201be6:	96a2                	add	a3,a3,s0
ffffffffc0201be8:	02d78a63          	beq	a5,a3,ffffffffc0201c1c <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201bec:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201bee:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201bf0:	00469793          	slli	a5,a3,0x4
ffffffffc0201bf4:	97ba                	add	a5,a5,a4
ffffffffc0201bf6:	02f40e63          	beq	s0,a5,ffffffffc0201c32 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201bfa:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201bfc:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201bfe:	e129                	bnez	a0,ffffffffc0201c40 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201c00:	60a2                	ld	ra,8(sp)
ffffffffc0201c02:	6402                	ld	s0,0(sp)
ffffffffc0201c04:	0141                	addi	sp,sp,16
ffffffffc0201c06:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201c08:	fcf764e3          	bltu	a4,a5,ffffffffc0201bd0 <slob_free+0x20>
ffffffffc0201c0c:	fcf472e3          	bgeu	s0,a5,ffffffffc0201bd0 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201c10:	400c                	lw	a1,0(s0)
ffffffffc0201c12:	00459693          	slli	a3,a1,0x4
ffffffffc0201c16:	96a2                	add	a3,a3,s0
ffffffffc0201c18:	fcd79ae3          	bne	a5,a3,ffffffffc0201bec <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201c1c:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201c1e:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201c20:	9db5                	addw	a1,a1,a3
ffffffffc0201c22:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201c24:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201c26:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201c28:	00469793          	slli	a5,a3,0x4
ffffffffc0201c2c:	97ba                	add	a5,a5,a4
ffffffffc0201c2e:	fcf416e3          	bne	s0,a5,ffffffffc0201bfa <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201c32:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201c34:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201c36:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201c38:	9ebd                	addw	a3,a3,a5
ffffffffc0201c3a:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201c3c:	e70c                	sd	a1,8(a4)
ffffffffc0201c3e:	d169                	beqz	a0,ffffffffc0201c00 <slob_free+0x50>
}
ffffffffc0201c40:	6402                	ld	s0,0(sp)
ffffffffc0201c42:	60a2                	ld	ra,8(sp)
ffffffffc0201c44:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201c46:	d69fe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201c4a:	25bd                	addiw	a1,a1,15
ffffffffc0201c4c:	8191                	srli	a1,a1,0x4
ffffffffc0201c4e:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c50:	100027f3          	csrr	a5,sstatus
ffffffffc0201c54:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201c56:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c58:	d7bd                	beqz	a5,ffffffffc0201bc6 <slob_free+0x16>
        intr_disable();
ffffffffc0201c5a:	d5bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201c5e:	4505                	li	a0,1
ffffffffc0201c60:	b79d                	j	ffffffffc0201bc6 <slob_free+0x16>
ffffffffc0201c62:	8082                	ret

ffffffffc0201c64 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201c64:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201c66:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201c68:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201c6c:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201c6e:	352000ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
	if (!page)
ffffffffc0201c72:	c91d                	beqz	a0,ffffffffc0201ca8 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201c74:	000a9697          	auipc	a3,0xa9
ffffffffc0201c78:	a646b683          	ld	a3,-1436(a3) # ffffffffc02aa6d8 <pages>
ffffffffc0201c7c:	8d15                	sub	a0,a0,a3
ffffffffc0201c7e:	8519                	srai	a0,a0,0x6
ffffffffc0201c80:	00006697          	auipc	a3,0x6
ffffffffc0201c84:	cd06b683          	ld	a3,-816(a3) # ffffffffc0207950 <nbase>
ffffffffc0201c88:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201c8a:	00c51793          	slli	a5,a0,0xc
ffffffffc0201c8e:	83b1                	srli	a5,a5,0xc
ffffffffc0201c90:	000a9717          	auipc	a4,0xa9
ffffffffc0201c94:	a4073703          	ld	a4,-1472(a4) # ffffffffc02aa6d0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201c98:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201c9a:	00e7fa63          	bgeu	a5,a4,ffffffffc0201cae <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201c9e:	000a9697          	auipc	a3,0xa9
ffffffffc0201ca2:	a4a6b683          	ld	a3,-1462(a3) # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc0201ca6:	9536                	add	a0,a0,a3
}
ffffffffc0201ca8:	60a2                	ld	ra,8(sp)
ffffffffc0201caa:	0141                	addi	sp,sp,16
ffffffffc0201cac:	8082                	ret
ffffffffc0201cae:	86aa                	mv	a3,a0
ffffffffc0201cb0:	00004617          	auipc	a2,0x4
ffffffffc0201cb4:	59860613          	addi	a2,a2,1432 # ffffffffc0206248 <commands+0x7b0>
ffffffffc0201cb8:	07100593          	li	a1,113
ffffffffc0201cbc:	00004517          	auipc	a0,0x4
ffffffffc0201cc0:	5b450513          	addi	a0,a0,1460 # ffffffffc0206270 <commands+0x7d8>
ffffffffc0201cc4:	fcafe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201cc8 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201cc8:	1101                	addi	sp,sp,-32
ffffffffc0201cca:	ec06                	sd	ra,24(sp)
ffffffffc0201ccc:	e822                	sd	s0,16(sp)
ffffffffc0201cce:	e426                	sd	s1,8(sp)
ffffffffc0201cd0:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201cd2:	01050713          	addi	a4,a0,16
ffffffffc0201cd6:	6785                	lui	a5,0x1
ffffffffc0201cd8:	0cf77363          	bgeu	a4,a5,ffffffffc0201d9e <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201cdc:	00f50493          	addi	s1,a0,15
ffffffffc0201ce0:	8091                	srli	s1,s1,0x4
ffffffffc0201ce2:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ce4:	10002673          	csrr	a2,sstatus
ffffffffc0201ce8:	8a09                	andi	a2,a2,2
ffffffffc0201cea:	e25d                	bnez	a2,ffffffffc0201d90 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201cec:	000a4917          	auipc	s2,0xa4
ffffffffc0201cf0:	56c90913          	addi	s2,s2,1388 # ffffffffc02a6258 <slobfree>
ffffffffc0201cf4:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201cf8:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201cfa:	4398                	lw	a4,0(a5)
ffffffffc0201cfc:	08975e63          	bge	a4,s1,ffffffffc0201d98 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201d00:	00f68b63          	beq	a3,a5,ffffffffc0201d16 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201d04:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201d06:	4018                	lw	a4,0(s0)
ffffffffc0201d08:	02975a63          	bge	a4,s1,ffffffffc0201d3c <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201d0c:	00093683          	ld	a3,0(s2)
ffffffffc0201d10:	87a2                	mv	a5,s0
ffffffffc0201d12:	fef699e3          	bne	a3,a5,ffffffffc0201d04 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201d16:	ee31                	bnez	a2,ffffffffc0201d72 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201d18:	4501                	li	a0,0
ffffffffc0201d1a:	f4bff0ef          	jal	ra,ffffffffc0201c64 <__slob_get_free_pages.constprop.0>
ffffffffc0201d1e:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201d20:	cd05                	beqz	a0,ffffffffc0201d58 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201d22:	6585                	lui	a1,0x1
ffffffffc0201d24:	e8dff0ef          	jal	ra,ffffffffc0201bb0 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d28:	10002673          	csrr	a2,sstatus
ffffffffc0201d2c:	8a09                	andi	a2,a2,2
ffffffffc0201d2e:	ee05                	bnez	a2,ffffffffc0201d66 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201d30:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201d34:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201d36:	4018                	lw	a4,0(s0)
ffffffffc0201d38:	fc974ae3          	blt	a4,s1,ffffffffc0201d0c <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201d3c:	04e48763          	beq	s1,a4,ffffffffc0201d8a <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201d40:	00449693          	slli	a3,s1,0x4
ffffffffc0201d44:	96a2                	add	a3,a3,s0
ffffffffc0201d46:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201d48:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201d4a:	9f05                	subw	a4,a4,s1
ffffffffc0201d4c:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201d4e:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201d50:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201d52:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201d56:	e20d                	bnez	a2,ffffffffc0201d78 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201d58:	60e2                	ld	ra,24(sp)
ffffffffc0201d5a:	8522                	mv	a0,s0
ffffffffc0201d5c:	6442                	ld	s0,16(sp)
ffffffffc0201d5e:	64a2                	ld	s1,8(sp)
ffffffffc0201d60:	6902                	ld	s2,0(sp)
ffffffffc0201d62:	6105                	addi	sp,sp,32
ffffffffc0201d64:	8082                	ret
        intr_disable();
ffffffffc0201d66:	c4ffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201d6a:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201d6e:	4605                	li	a2,1
ffffffffc0201d70:	b7d1                	j	ffffffffc0201d34 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201d72:	c3dfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201d76:	b74d                	j	ffffffffc0201d18 <slob_alloc.constprop.0+0x50>
ffffffffc0201d78:	c37fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201d7c:	60e2                	ld	ra,24(sp)
ffffffffc0201d7e:	8522                	mv	a0,s0
ffffffffc0201d80:	6442                	ld	s0,16(sp)
ffffffffc0201d82:	64a2                	ld	s1,8(sp)
ffffffffc0201d84:	6902                	ld	s2,0(sp)
ffffffffc0201d86:	6105                	addi	sp,sp,32
ffffffffc0201d88:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201d8a:	6418                	ld	a4,8(s0)
ffffffffc0201d8c:	e798                	sd	a4,8(a5)
ffffffffc0201d8e:	b7d1                	j	ffffffffc0201d52 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201d90:	c25fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201d94:	4605                	li	a2,1
ffffffffc0201d96:	bf99                	j	ffffffffc0201cec <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201d98:	843e                	mv	s0,a5
ffffffffc0201d9a:	87b6                	mv	a5,a3
ffffffffc0201d9c:	b745                	j	ffffffffc0201d3c <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201d9e:	00005697          	auipc	a3,0x5
ffffffffc0201da2:	93a68693          	addi	a3,a3,-1734 # ffffffffc02066d8 <default_pmm_manager+0x38>
ffffffffc0201da6:	00004617          	auipc	a2,0x4
ffffffffc0201daa:	54a60613          	addi	a2,a2,1354 # ffffffffc02062f0 <commands+0x858>
ffffffffc0201dae:	06300593          	li	a1,99
ffffffffc0201db2:	00005517          	auipc	a0,0x5
ffffffffc0201db6:	94650513          	addi	a0,a0,-1722 # ffffffffc02066f8 <default_pmm_manager+0x58>
ffffffffc0201dba:	ed4fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201dbe <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201dbe:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201dc0:	00005517          	auipc	a0,0x5
ffffffffc0201dc4:	95050513          	addi	a0,a0,-1712 # ffffffffc0206710 <default_pmm_manager+0x70>
{
ffffffffc0201dc8:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201dca:	bcafe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201dce:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201dd0:	00005517          	auipc	a0,0x5
ffffffffc0201dd4:	95850513          	addi	a0,a0,-1704 # ffffffffc0206728 <default_pmm_manager+0x88>
}
ffffffffc0201dd8:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201dda:	bbafe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201dde <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201dde:	4501                	li	a0,0
ffffffffc0201de0:	8082                	ret

ffffffffc0201de2 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201de2:	1101                	addi	sp,sp,-32
ffffffffc0201de4:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201de6:	6905                	lui	s2,0x1
{
ffffffffc0201de8:	e822                	sd	s0,16(sp)
ffffffffc0201dea:	ec06                	sd	ra,24(sp)
ffffffffc0201dec:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201dee:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bb9>
{
ffffffffc0201df2:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201df4:	04a7f963          	bgeu	a5,a0,ffffffffc0201e46 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201df8:	4561                	li	a0,24
ffffffffc0201dfa:	ecfff0ef          	jal	ra,ffffffffc0201cc8 <slob_alloc.constprop.0>
ffffffffc0201dfe:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201e00:	c929                	beqz	a0,ffffffffc0201e52 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201e02:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201e06:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201e08:	00f95763          	bge	s2,a5,ffffffffc0201e16 <kmalloc+0x34>
ffffffffc0201e0c:	6705                	lui	a4,0x1
ffffffffc0201e0e:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201e10:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201e12:	fef74ee3          	blt	a4,a5,ffffffffc0201e0e <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201e16:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201e18:	e4dff0ef          	jal	ra,ffffffffc0201c64 <__slob_get_free_pages.constprop.0>
ffffffffc0201e1c:	e488                	sd	a0,8(s1)
ffffffffc0201e1e:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201e20:	c525                	beqz	a0,ffffffffc0201e88 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e22:	100027f3          	csrr	a5,sstatus
ffffffffc0201e26:	8b89                	andi	a5,a5,2
ffffffffc0201e28:	ef8d                	bnez	a5,ffffffffc0201e62 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201e2a:	000a9797          	auipc	a5,0xa9
ffffffffc0201e2e:	88e78793          	addi	a5,a5,-1906 # ffffffffc02aa6b8 <bigblocks>
ffffffffc0201e32:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201e34:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201e36:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201e38:	60e2                	ld	ra,24(sp)
ffffffffc0201e3a:	8522                	mv	a0,s0
ffffffffc0201e3c:	6442                	ld	s0,16(sp)
ffffffffc0201e3e:	64a2                	ld	s1,8(sp)
ffffffffc0201e40:	6902                	ld	s2,0(sp)
ffffffffc0201e42:	6105                	addi	sp,sp,32
ffffffffc0201e44:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201e46:	0541                	addi	a0,a0,16
ffffffffc0201e48:	e81ff0ef          	jal	ra,ffffffffc0201cc8 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201e4c:	01050413          	addi	s0,a0,16
ffffffffc0201e50:	f565                	bnez	a0,ffffffffc0201e38 <kmalloc+0x56>
ffffffffc0201e52:	4401                	li	s0,0
}
ffffffffc0201e54:	60e2                	ld	ra,24(sp)
ffffffffc0201e56:	8522                	mv	a0,s0
ffffffffc0201e58:	6442                	ld	s0,16(sp)
ffffffffc0201e5a:	64a2                	ld	s1,8(sp)
ffffffffc0201e5c:	6902                	ld	s2,0(sp)
ffffffffc0201e5e:	6105                	addi	sp,sp,32
ffffffffc0201e60:	8082                	ret
        intr_disable();
ffffffffc0201e62:	b53fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201e66:	000a9797          	auipc	a5,0xa9
ffffffffc0201e6a:	85278793          	addi	a5,a5,-1966 # ffffffffc02aa6b8 <bigblocks>
ffffffffc0201e6e:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201e70:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201e72:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201e74:	b3bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201e78:	6480                	ld	s0,8(s1)
}
ffffffffc0201e7a:	60e2                	ld	ra,24(sp)
ffffffffc0201e7c:	64a2                	ld	s1,8(sp)
ffffffffc0201e7e:	8522                	mv	a0,s0
ffffffffc0201e80:	6442                	ld	s0,16(sp)
ffffffffc0201e82:	6902                	ld	s2,0(sp)
ffffffffc0201e84:	6105                	addi	sp,sp,32
ffffffffc0201e86:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e88:	45e1                	li	a1,24
ffffffffc0201e8a:	8526                	mv	a0,s1
ffffffffc0201e8c:	d25ff0ef          	jal	ra,ffffffffc0201bb0 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201e90:	b765                	j	ffffffffc0201e38 <kmalloc+0x56>

ffffffffc0201e92 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201e92:	c169                	beqz	a0,ffffffffc0201f54 <kfree+0xc2>
{
ffffffffc0201e94:	1101                	addi	sp,sp,-32
ffffffffc0201e96:	e822                	sd	s0,16(sp)
ffffffffc0201e98:	ec06                	sd	ra,24(sp)
ffffffffc0201e9a:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201e9c:	03451793          	slli	a5,a0,0x34
ffffffffc0201ea0:	842a                	mv	s0,a0
ffffffffc0201ea2:	e3d9                	bnez	a5,ffffffffc0201f28 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ea4:	100027f3          	csrr	a5,sstatus
ffffffffc0201ea8:	8b89                	andi	a5,a5,2
ffffffffc0201eaa:	e7d9                	bnez	a5,ffffffffc0201f38 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201eac:	000a9797          	auipc	a5,0xa9
ffffffffc0201eb0:	80c7b783          	ld	a5,-2036(a5) # ffffffffc02aa6b8 <bigblocks>
    return 0;
ffffffffc0201eb4:	4601                	li	a2,0
ffffffffc0201eb6:	cbad                	beqz	a5,ffffffffc0201f28 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201eb8:	000a9697          	auipc	a3,0xa9
ffffffffc0201ebc:	80068693          	addi	a3,a3,-2048 # ffffffffc02aa6b8 <bigblocks>
ffffffffc0201ec0:	a021                	j	ffffffffc0201ec8 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201ec2:	01048693          	addi	a3,s1,16 # fffffffffffff010 <end+0x3fd54904>
ffffffffc0201ec6:	c3a5                	beqz	a5,ffffffffc0201f26 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201ec8:	6798                	ld	a4,8(a5)
ffffffffc0201eca:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201ecc:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201ece:	fe871ae3          	bne	a4,s0,ffffffffc0201ec2 <kfree+0x30>
				*last = bb->next;
ffffffffc0201ed2:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201ed4:	ee2d                	bnez	a2,ffffffffc0201f4e <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201ed6:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201eda:	4098                	lw	a4,0(s1)
ffffffffc0201edc:	08f46963          	bltu	s0,a5,ffffffffc0201f6e <kfree+0xdc>
ffffffffc0201ee0:	000a9697          	auipc	a3,0xa9
ffffffffc0201ee4:	8086b683          	ld	a3,-2040(a3) # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc0201ee8:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201eea:	8031                	srli	s0,s0,0xc
ffffffffc0201eec:	000a8797          	auipc	a5,0xa8
ffffffffc0201ef0:	7e47b783          	ld	a5,2020(a5) # ffffffffc02aa6d0 <npage>
ffffffffc0201ef4:	06f47163          	bgeu	s0,a5,ffffffffc0201f56 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ef8:	00006517          	auipc	a0,0x6
ffffffffc0201efc:	a5853503          	ld	a0,-1448(a0) # ffffffffc0207950 <nbase>
ffffffffc0201f00:	8c09                	sub	s0,s0,a0
ffffffffc0201f02:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201f04:	000a8517          	auipc	a0,0xa8
ffffffffc0201f08:	7d453503          	ld	a0,2004(a0) # ffffffffc02aa6d8 <pages>
ffffffffc0201f0c:	4585                	li	a1,1
ffffffffc0201f0e:	9522                	add	a0,a0,s0
ffffffffc0201f10:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201f14:	0ea000ef          	jal	ra,ffffffffc0201ffe <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201f18:	6442                	ld	s0,16(sp)
ffffffffc0201f1a:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201f1c:	8526                	mv	a0,s1
}
ffffffffc0201f1e:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201f20:	45e1                	li	a1,24
}
ffffffffc0201f22:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201f24:	b171                	j	ffffffffc0201bb0 <slob_free>
ffffffffc0201f26:	e20d                	bnez	a2,ffffffffc0201f48 <kfree+0xb6>
ffffffffc0201f28:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201f2c:	6442                	ld	s0,16(sp)
ffffffffc0201f2e:	60e2                	ld	ra,24(sp)
ffffffffc0201f30:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201f32:	4581                	li	a1,0
}
ffffffffc0201f34:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201f36:	b9ad                	j	ffffffffc0201bb0 <slob_free>
        intr_disable();
ffffffffc0201f38:	a7dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201f3c:	000a8797          	auipc	a5,0xa8
ffffffffc0201f40:	77c7b783          	ld	a5,1916(a5) # ffffffffc02aa6b8 <bigblocks>
        return 1;
ffffffffc0201f44:	4605                	li	a2,1
ffffffffc0201f46:	fbad                	bnez	a5,ffffffffc0201eb8 <kfree+0x26>
        intr_enable();
ffffffffc0201f48:	a67fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201f4c:	bff1                	j	ffffffffc0201f28 <kfree+0x96>
ffffffffc0201f4e:	a61fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201f52:	b751                	j	ffffffffc0201ed6 <kfree+0x44>
ffffffffc0201f54:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201f56:	00005617          	auipc	a2,0x5
ffffffffc0201f5a:	81a60613          	addi	a2,a2,-2022 # ffffffffc0206770 <default_pmm_manager+0xd0>
ffffffffc0201f5e:	06900593          	li	a1,105
ffffffffc0201f62:	00004517          	auipc	a0,0x4
ffffffffc0201f66:	30e50513          	addi	a0,a0,782 # ffffffffc0206270 <commands+0x7d8>
ffffffffc0201f6a:	d24fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201f6e:	86a2                	mv	a3,s0
ffffffffc0201f70:	00004617          	auipc	a2,0x4
ffffffffc0201f74:	7d860613          	addi	a2,a2,2008 # ffffffffc0206748 <default_pmm_manager+0xa8>
ffffffffc0201f78:	07700593          	li	a1,119
ffffffffc0201f7c:	00004517          	auipc	a0,0x4
ffffffffc0201f80:	2f450513          	addi	a0,a0,756 # ffffffffc0206270 <commands+0x7d8>
ffffffffc0201f84:	d0afe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f88 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201f88:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201f8a:	00004617          	auipc	a2,0x4
ffffffffc0201f8e:	7e660613          	addi	a2,a2,2022 # ffffffffc0206770 <default_pmm_manager+0xd0>
ffffffffc0201f92:	06900593          	li	a1,105
ffffffffc0201f96:	00004517          	auipc	a0,0x4
ffffffffc0201f9a:	2da50513          	addi	a0,a0,730 # ffffffffc0206270 <commands+0x7d8>
pa2page(uintptr_t pa)
ffffffffc0201f9e:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201fa0:	ceefe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201fa4 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201fa4:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201fa6:	00004617          	auipc	a2,0x4
ffffffffc0201faa:	7ea60613          	addi	a2,a2,2026 # ffffffffc0206790 <default_pmm_manager+0xf0>
ffffffffc0201fae:	07f00593          	li	a1,127
ffffffffc0201fb2:	00004517          	auipc	a0,0x4
ffffffffc0201fb6:	2be50513          	addi	a0,a0,702 # ffffffffc0206270 <commands+0x7d8>
pte2page(pte_t pte)
ffffffffc0201fba:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201fbc:	cd2fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201fc0 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201fc0:	100027f3          	csrr	a5,sstatus
ffffffffc0201fc4:	8b89                	andi	a5,a5,2
ffffffffc0201fc6:	e799                	bnez	a5,ffffffffc0201fd4 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201fc8:	000a8797          	auipc	a5,0xa8
ffffffffc0201fcc:	7187b783          	ld	a5,1816(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0201fd0:	6f9c                	ld	a5,24(a5)
ffffffffc0201fd2:	8782                	jr	a5
{
ffffffffc0201fd4:	1141                	addi	sp,sp,-16
ffffffffc0201fd6:	e406                	sd	ra,8(sp)
ffffffffc0201fd8:	e022                	sd	s0,0(sp)
ffffffffc0201fda:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201fdc:	9d9fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201fe0:	000a8797          	auipc	a5,0xa8
ffffffffc0201fe4:	7007b783          	ld	a5,1792(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0201fe8:	6f9c                	ld	a5,24(a5)
ffffffffc0201fea:	8522                	mv	a0,s0
ffffffffc0201fec:	9782                	jalr	a5
ffffffffc0201fee:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201ff0:	9bffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201ff4:	60a2                	ld	ra,8(sp)
ffffffffc0201ff6:	8522                	mv	a0,s0
ffffffffc0201ff8:	6402                	ld	s0,0(sp)
ffffffffc0201ffa:	0141                	addi	sp,sp,16
ffffffffc0201ffc:	8082                	ret

ffffffffc0201ffe <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ffe:	100027f3          	csrr	a5,sstatus
ffffffffc0202002:	8b89                	andi	a5,a5,2
ffffffffc0202004:	e799                	bnez	a5,ffffffffc0202012 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0202006:	000a8797          	auipc	a5,0xa8
ffffffffc020200a:	6da7b783          	ld	a5,1754(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc020200e:	739c                	ld	a5,32(a5)
ffffffffc0202010:	8782                	jr	a5
{
ffffffffc0202012:	1101                	addi	sp,sp,-32
ffffffffc0202014:	ec06                	sd	ra,24(sp)
ffffffffc0202016:	e822                	sd	s0,16(sp)
ffffffffc0202018:	e426                	sd	s1,8(sp)
ffffffffc020201a:	842a                	mv	s0,a0
ffffffffc020201c:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020201e:	997fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202022:	000a8797          	auipc	a5,0xa8
ffffffffc0202026:	6be7b783          	ld	a5,1726(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc020202a:	739c                	ld	a5,32(a5)
ffffffffc020202c:	85a6                	mv	a1,s1
ffffffffc020202e:	8522                	mv	a0,s0
ffffffffc0202030:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0202032:	6442                	ld	s0,16(sp)
ffffffffc0202034:	60e2                	ld	ra,24(sp)
ffffffffc0202036:	64a2                	ld	s1,8(sp)
ffffffffc0202038:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020203a:	975fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc020203e <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020203e:	100027f3          	csrr	a5,sstatus
ffffffffc0202042:	8b89                	andi	a5,a5,2
ffffffffc0202044:	e799                	bnez	a5,ffffffffc0202052 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0202046:	000a8797          	auipc	a5,0xa8
ffffffffc020204a:	69a7b783          	ld	a5,1690(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc020204e:	779c                	ld	a5,40(a5)
ffffffffc0202050:	8782                	jr	a5
{
ffffffffc0202052:	1141                	addi	sp,sp,-16
ffffffffc0202054:	e406                	sd	ra,8(sp)
ffffffffc0202056:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0202058:	95dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020205c:	000a8797          	auipc	a5,0xa8
ffffffffc0202060:	6847b783          	ld	a5,1668(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0202064:	779c                	ld	a5,40(a5)
ffffffffc0202066:	9782                	jalr	a5
ffffffffc0202068:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020206a:	945fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc020206e:	60a2                	ld	ra,8(sp)
ffffffffc0202070:	8522                	mv	a0,s0
ffffffffc0202072:	6402                	ld	s0,0(sp)
ffffffffc0202074:	0141                	addi	sp,sp,16
ffffffffc0202076:	8082                	ret

ffffffffc0202078 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202078:	01e5d793          	srli	a5,a1,0x1e
ffffffffc020207c:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0202080:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202082:	078e                	slli	a5,a5,0x3
{
ffffffffc0202084:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202086:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc020208a:	6094                	ld	a3,0(s1)
{
ffffffffc020208c:	f04a                	sd	s2,32(sp)
ffffffffc020208e:	ec4e                	sd	s3,24(sp)
ffffffffc0202090:	e852                	sd	s4,16(sp)
ffffffffc0202092:	fc06                	sd	ra,56(sp)
ffffffffc0202094:	f822                	sd	s0,48(sp)
ffffffffc0202096:	e456                	sd	s5,8(sp)
ffffffffc0202098:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc020209a:	0016f793          	andi	a5,a3,1
{
ffffffffc020209e:	892e                	mv	s2,a1
ffffffffc02020a0:	8a32                	mv	s4,a2
ffffffffc02020a2:	000a8997          	auipc	s3,0xa8
ffffffffc02020a6:	62e98993          	addi	s3,s3,1582 # ffffffffc02aa6d0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc02020aa:	efbd                	bnez	a5,ffffffffc0202128 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02020ac:	14060c63          	beqz	a2,ffffffffc0202204 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02020b0:	100027f3          	csrr	a5,sstatus
ffffffffc02020b4:	8b89                	andi	a5,a5,2
ffffffffc02020b6:	14079963          	bnez	a5,ffffffffc0202208 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020ba:	000a8797          	auipc	a5,0xa8
ffffffffc02020be:	6267b783          	ld	a5,1574(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc02020c2:	6f9c                	ld	a5,24(a5)
ffffffffc02020c4:	4505                	li	a0,1
ffffffffc02020c6:	9782                	jalr	a5
ffffffffc02020c8:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02020ca:	12040d63          	beqz	s0,ffffffffc0202204 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc02020ce:	000a8b17          	auipc	s6,0xa8
ffffffffc02020d2:	60ab0b13          	addi	s6,s6,1546 # ffffffffc02aa6d8 <pages>
ffffffffc02020d6:	000b3503          	ld	a0,0(s6)
ffffffffc02020da:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020de:	000a8997          	auipc	s3,0xa8
ffffffffc02020e2:	5f298993          	addi	s3,s3,1522 # ffffffffc02aa6d0 <npage>
ffffffffc02020e6:	40a40533          	sub	a0,s0,a0
ffffffffc02020ea:	8519                	srai	a0,a0,0x6
ffffffffc02020ec:	9556                	add	a0,a0,s5
ffffffffc02020ee:	0009b703          	ld	a4,0(s3)
ffffffffc02020f2:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc02020f6:	4685                	li	a3,1
ffffffffc02020f8:	c014                	sw	a3,0(s0)
ffffffffc02020fa:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02020fc:	0532                	slli	a0,a0,0xc
ffffffffc02020fe:	16e7f763          	bgeu	a5,a4,ffffffffc020226c <get_pte+0x1f4>
ffffffffc0202102:	000a8797          	auipc	a5,0xa8
ffffffffc0202106:	5e67b783          	ld	a5,1510(a5) # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc020210a:	6605                	lui	a2,0x1
ffffffffc020210c:	4581                	li	a1,0
ffffffffc020210e:	953e                	add	a0,a0,a5
ffffffffc0202110:	6f2030ef          	jal	ra,ffffffffc0205802 <memset>
    return page - pages + nbase;
ffffffffc0202114:	000b3683          	ld	a3,0(s6)
ffffffffc0202118:	40d406b3          	sub	a3,s0,a3
ffffffffc020211c:	8699                	srai	a3,a3,0x6
ffffffffc020211e:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202120:	06aa                	slli	a3,a3,0xa
ffffffffc0202122:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202126:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202128:	77fd                	lui	a5,0xfffff
ffffffffc020212a:	068a                	slli	a3,a3,0x2
ffffffffc020212c:	0009b703          	ld	a4,0(s3)
ffffffffc0202130:	8efd                	and	a3,a3,a5
ffffffffc0202132:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202136:	10e7ff63          	bgeu	a5,a4,ffffffffc0202254 <get_pte+0x1dc>
ffffffffc020213a:	000a8a97          	auipc	s5,0xa8
ffffffffc020213e:	5aea8a93          	addi	s5,s5,1454 # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc0202142:	000ab403          	ld	s0,0(s5)
ffffffffc0202146:	01595793          	srli	a5,s2,0x15
ffffffffc020214a:	1ff7f793          	andi	a5,a5,511
ffffffffc020214e:	96a2                	add	a3,a3,s0
ffffffffc0202150:	00379413          	slli	s0,a5,0x3
ffffffffc0202154:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0202156:	6014                	ld	a3,0(s0)
ffffffffc0202158:	0016f793          	andi	a5,a3,1
ffffffffc020215c:	ebad                	bnez	a5,ffffffffc02021ce <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020215e:	0a0a0363          	beqz	s4,ffffffffc0202204 <get_pte+0x18c>
ffffffffc0202162:	100027f3          	csrr	a5,sstatus
ffffffffc0202166:	8b89                	andi	a5,a5,2
ffffffffc0202168:	efcd                	bnez	a5,ffffffffc0202222 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc020216a:	000a8797          	auipc	a5,0xa8
ffffffffc020216e:	5767b783          	ld	a5,1398(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0202172:	6f9c                	ld	a5,24(a5)
ffffffffc0202174:	4505                	li	a0,1
ffffffffc0202176:	9782                	jalr	a5
ffffffffc0202178:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020217a:	c4c9                	beqz	s1,ffffffffc0202204 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc020217c:	000a8b17          	auipc	s6,0xa8
ffffffffc0202180:	55cb0b13          	addi	s6,s6,1372 # ffffffffc02aa6d8 <pages>
ffffffffc0202184:	000b3503          	ld	a0,0(s6)
ffffffffc0202188:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020218c:	0009b703          	ld	a4,0(s3)
ffffffffc0202190:	40a48533          	sub	a0,s1,a0
ffffffffc0202194:	8519                	srai	a0,a0,0x6
ffffffffc0202196:	9552                	add	a0,a0,s4
ffffffffc0202198:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc020219c:	4685                	li	a3,1
ffffffffc020219e:	c094                	sw	a3,0(s1)
ffffffffc02021a0:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02021a2:	0532                	slli	a0,a0,0xc
ffffffffc02021a4:	0ee7f163          	bgeu	a5,a4,ffffffffc0202286 <get_pte+0x20e>
ffffffffc02021a8:	000ab783          	ld	a5,0(s5)
ffffffffc02021ac:	6605                	lui	a2,0x1
ffffffffc02021ae:	4581                	li	a1,0
ffffffffc02021b0:	953e                	add	a0,a0,a5
ffffffffc02021b2:	650030ef          	jal	ra,ffffffffc0205802 <memset>
    return page - pages + nbase;
ffffffffc02021b6:	000b3683          	ld	a3,0(s6)
ffffffffc02021ba:	40d486b3          	sub	a3,s1,a3
ffffffffc02021be:	8699                	srai	a3,a3,0x6
ffffffffc02021c0:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02021c2:	06aa                	slli	a3,a3,0xa
ffffffffc02021c4:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02021c8:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02021ca:	0009b703          	ld	a4,0(s3)
ffffffffc02021ce:	068a                	slli	a3,a3,0x2
ffffffffc02021d0:	757d                	lui	a0,0xfffff
ffffffffc02021d2:	8ee9                	and	a3,a3,a0
ffffffffc02021d4:	00c6d793          	srli	a5,a3,0xc
ffffffffc02021d8:	06e7f263          	bgeu	a5,a4,ffffffffc020223c <get_pte+0x1c4>
ffffffffc02021dc:	000ab503          	ld	a0,0(s5)
ffffffffc02021e0:	00c95913          	srli	s2,s2,0xc
ffffffffc02021e4:	1ff97913          	andi	s2,s2,511
ffffffffc02021e8:	96aa                	add	a3,a3,a0
ffffffffc02021ea:	00391513          	slli	a0,s2,0x3
ffffffffc02021ee:	9536                	add	a0,a0,a3
}
ffffffffc02021f0:	70e2                	ld	ra,56(sp)
ffffffffc02021f2:	7442                	ld	s0,48(sp)
ffffffffc02021f4:	74a2                	ld	s1,40(sp)
ffffffffc02021f6:	7902                	ld	s2,32(sp)
ffffffffc02021f8:	69e2                	ld	s3,24(sp)
ffffffffc02021fa:	6a42                	ld	s4,16(sp)
ffffffffc02021fc:	6aa2                	ld	s5,8(sp)
ffffffffc02021fe:	6b02                	ld	s6,0(sp)
ffffffffc0202200:	6121                	addi	sp,sp,64
ffffffffc0202202:	8082                	ret
            return NULL;
ffffffffc0202204:	4501                	li	a0,0
ffffffffc0202206:	b7ed                	j	ffffffffc02021f0 <get_pte+0x178>
        intr_disable();
ffffffffc0202208:	facfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020220c:	000a8797          	auipc	a5,0xa8
ffffffffc0202210:	4d47b783          	ld	a5,1236(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0202214:	6f9c                	ld	a5,24(a5)
ffffffffc0202216:	4505                	li	a0,1
ffffffffc0202218:	9782                	jalr	a5
ffffffffc020221a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020221c:	f92fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202220:	b56d                	j	ffffffffc02020ca <get_pte+0x52>
        intr_disable();
ffffffffc0202222:	f92fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202226:	000a8797          	auipc	a5,0xa8
ffffffffc020222a:	4ba7b783          	ld	a5,1210(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc020222e:	6f9c                	ld	a5,24(a5)
ffffffffc0202230:	4505                	li	a0,1
ffffffffc0202232:	9782                	jalr	a5
ffffffffc0202234:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0202236:	f78fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020223a:	b781                	j	ffffffffc020217a <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020223c:	00004617          	auipc	a2,0x4
ffffffffc0202240:	00c60613          	addi	a2,a2,12 # ffffffffc0206248 <commands+0x7b0>
ffffffffc0202244:	0fa00593          	li	a1,250
ffffffffc0202248:	00004517          	auipc	a0,0x4
ffffffffc020224c:	57050513          	addi	a0,a0,1392 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0202250:	a3efe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202254:	00004617          	auipc	a2,0x4
ffffffffc0202258:	ff460613          	addi	a2,a2,-12 # ffffffffc0206248 <commands+0x7b0>
ffffffffc020225c:	0ed00593          	li	a1,237
ffffffffc0202260:	00004517          	auipc	a0,0x4
ffffffffc0202264:	55850513          	addi	a0,a0,1368 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0202268:	a26fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020226c:	86aa                	mv	a3,a0
ffffffffc020226e:	00004617          	auipc	a2,0x4
ffffffffc0202272:	fda60613          	addi	a2,a2,-38 # ffffffffc0206248 <commands+0x7b0>
ffffffffc0202276:	0e900593          	li	a1,233
ffffffffc020227a:	00004517          	auipc	a0,0x4
ffffffffc020227e:	53e50513          	addi	a0,a0,1342 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0202282:	a0cfe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202286:	86aa                	mv	a3,a0
ffffffffc0202288:	00004617          	auipc	a2,0x4
ffffffffc020228c:	fc060613          	addi	a2,a2,-64 # ffffffffc0206248 <commands+0x7b0>
ffffffffc0202290:	0f700593          	li	a1,247
ffffffffc0202294:	00004517          	auipc	a0,0x4
ffffffffc0202298:	52450513          	addi	a0,a0,1316 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc020229c:	9f2fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02022a0 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02022a0:	1141                	addi	sp,sp,-16
ffffffffc02022a2:	e022                	sd	s0,0(sp)
ffffffffc02022a4:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02022a6:	4601                	li	a2,0
{
ffffffffc02022a8:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02022aa:	dcfff0ef          	jal	ra,ffffffffc0202078 <get_pte>
    if (ptep_store != NULL)
ffffffffc02022ae:	c011                	beqz	s0,ffffffffc02022b2 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02022b0:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02022b2:	c511                	beqz	a0,ffffffffc02022be <get_page+0x1e>
ffffffffc02022b4:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02022b6:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02022b8:	0017f713          	andi	a4,a5,1
ffffffffc02022bc:	e709                	bnez	a4,ffffffffc02022c6 <get_page+0x26>
}
ffffffffc02022be:	60a2                	ld	ra,8(sp)
ffffffffc02022c0:	6402                	ld	s0,0(sp)
ffffffffc02022c2:	0141                	addi	sp,sp,16
ffffffffc02022c4:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02022c6:	078a                	slli	a5,a5,0x2
ffffffffc02022c8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02022ca:	000a8717          	auipc	a4,0xa8
ffffffffc02022ce:	40673703          	ld	a4,1030(a4) # ffffffffc02aa6d0 <npage>
ffffffffc02022d2:	00e7ff63          	bgeu	a5,a4,ffffffffc02022f0 <get_page+0x50>
ffffffffc02022d6:	60a2                	ld	ra,8(sp)
ffffffffc02022d8:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02022da:	fff80537          	lui	a0,0xfff80
ffffffffc02022de:	97aa                	add	a5,a5,a0
ffffffffc02022e0:	079a                	slli	a5,a5,0x6
ffffffffc02022e2:	000a8517          	auipc	a0,0xa8
ffffffffc02022e6:	3f653503          	ld	a0,1014(a0) # ffffffffc02aa6d8 <pages>
ffffffffc02022ea:	953e                	add	a0,a0,a5
ffffffffc02022ec:	0141                	addi	sp,sp,16
ffffffffc02022ee:	8082                	ret
ffffffffc02022f0:	c99ff0ef          	jal	ra,ffffffffc0201f88 <pa2page.part.0>

ffffffffc02022f4 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02022f4:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022f6:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02022fa:	f486                	sd	ra,104(sp)
ffffffffc02022fc:	f0a2                	sd	s0,96(sp)
ffffffffc02022fe:	eca6                	sd	s1,88(sp)
ffffffffc0202300:	e8ca                	sd	s2,80(sp)
ffffffffc0202302:	e4ce                	sd	s3,72(sp)
ffffffffc0202304:	e0d2                	sd	s4,64(sp)
ffffffffc0202306:	fc56                	sd	s5,56(sp)
ffffffffc0202308:	f85a                	sd	s6,48(sp)
ffffffffc020230a:	f45e                	sd	s7,40(sp)
ffffffffc020230c:	f062                	sd	s8,32(sp)
ffffffffc020230e:	ec66                	sd	s9,24(sp)
ffffffffc0202310:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202312:	17d2                	slli	a5,a5,0x34
ffffffffc0202314:	e3ed                	bnez	a5,ffffffffc02023f6 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc0202316:	002007b7          	lui	a5,0x200
ffffffffc020231a:	842e                	mv	s0,a1
ffffffffc020231c:	0ef5ed63          	bltu	a1,a5,ffffffffc0202416 <unmap_range+0x122>
ffffffffc0202320:	8932                	mv	s2,a2
ffffffffc0202322:	0ec5fa63          	bgeu	a1,a2,ffffffffc0202416 <unmap_range+0x122>
ffffffffc0202326:	4785                	li	a5,1
ffffffffc0202328:	07fe                	slli	a5,a5,0x1f
ffffffffc020232a:	0ec7e663          	bltu	a5,a2,ffffffffc0202416 <unmap_range+0x122>
ffffffffc020232e:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc0202330:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc0202332:	000a8c97          	auipc	s9,0xa8
ffffffffc0202336:	39ec8c93          	addi	s9,s9,926 # ffffffffc02aa6d0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020233a:	000a8c17          	auipc	s8,0xa8
ffffffffc020233e:	39ec0c13          	addi	s8,s8,926 # ffffffffc02aa6d8 <pages>
ffffffffc0202342:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc0202346:	000a8d17          	auipc	s10,0xa8
ffffffffc020234a:	39ad0d13          	addi	s10,s10,922 # ffffffffc02aa6e0 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020234e:	00200b37          	lui	s6,0x200
ffffffffc0202352:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202356:	4601                	li	a2,0
ffffffffc0202358:	85a2                	mv	a1,s0
ffffffffc020235a:	854e                	mv	a0,s3
ffffffffc020235c:	d1dff0ef          	jal	ra,ffffffffc0202078 <get_pte>
ffffffffc0202360:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc0202362:	cd29                	beqz	a0,ffffffffc02023bc <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc0202364:	611c                	ld	a5,0(a0)
ffffffffc0202366:	e395                	bnez	a5,ffffffffc020238a <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202368:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020236a:	ff2466e3          	bltu	s0,s2,ffffffffc0202356 <unmap_range+0x62>
}
ffffffffc020236e:	70a6                	ld	ra,104(sp)
ffffffffc0202370:	7406                	ld	s0,96(sp)
ffffffffc0202372:	64e6                	ld	s1,88(sp)
ffffffffc0202374:	6946                	ld	s2,80(sp)
ffffffffc0202376:	69a6                	ld	s3,72(sp)
ffffffffc0202378:	6a06                	ld	s4,64(sp)
ffffffffc020237a:	7ae2                	ld	s5,56(sp)
ffffffffc020237c:	7b42                	ld	s6,48(sp)
ffffffffc020237e:	7ba2                	ld	s7,40(sp)
ffffffffc0202380:	7c02                	ld	s8,32(sp)
ffffffffc0202382:	6ce2                	ld	s9,24(sp)
ffffffffc0202384:	6d42                	ld	s10,16(sp)
ffffffffc0202386:	6165                	addi	sp,sp,112
ffffffffc0202388:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc020238a:	0017f713          	andi	a4,a5,1
ffffffffc020238e:	df69                	beqz	a4,ffffffffc0202368 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc0202390:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202394:	078a                	slli	a5,a5,0x2
ffffffffc0202396:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202398:	08e7ff63          	bgeu	a5,a4,ffffffffc0202436 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc020239c:	000c3503          	ld	a0,0(s8)
ffffffffc02023a0:	97de                	add	a5,a5,s7
ffffffffc02023a2:	079a                	slli	a5,a5,0x6
ffffffffc02023a4:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02023a6:	411c                	lw	a5,0(a0)
ffffffffc02023a8:	fff7871b          	addiw	a4,a5,-1
ffffffffc02023ac:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02023ae:	cf11                	beqz	a4,ffffffffc02023ca <unmap_range+0xd6>
        *ptep = 0;
ffffffffc02023b0:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02023b4:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc02023b8:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02023ba:	bf45                	j	ffffffffc020236a <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02023bc:	945a                	add	s0,s0,s6
ffffffffc02023be:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc02023c2:	d455                	beqz	s0,ffffffffc020236e <unmap_range+0x7a>
ffffffffc02023c4:	f92469e3          	bltu	s0,s2,ffffffffc0202356 <unmap_range+0x62>
ffffffffc02023c8:	b75d                	j	ffffffffc020236e <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02023ca:	100027f3          	csrr	a5,sstatus
ffffffffc02023ce:	8b89                	andi	a5,a5,2
ffffffffc02023d0:	e799                	bnez	a5,ffffffffc02023de <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc02023d2:	000d3783          	ld	a5,0(s10)
ffffffffc02023d6:	4585                	li	a1,1
ffffffffc02023d8:	739c                	ld	a5,32(a5)
ffffffffc02023da:	9782                	jalr	a5
    if (flag)
ffffffffc02023dc:	bfd1                	j	ffffffffc02023b0 <unmap_range+0xbc>
ffffffffc02023de:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02023e0:	dd4fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02023e4:	000d3783          	ld	a5,0(s10)
ffffffffc02023e8:	6522                	ld	a0,8(sp)
ffffffffc02023ea:	4585                	li	a1,1
ffffffffc02023ec:	739c                	ld	a5,32(a5)
ffffffffc02023ee:	9782                	jalr	a5
        intr_enable();
ffffffffc02023f0:	dbefe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02023f4:	bf75                	j	ffffffffc02023b0 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023f6:	00004697          	auipc	a3,0x4
ffffffffc02023fa:	3d268693          	addi	a3,a3,978 # ffffffffc02067c8 <default_pmm_manager+0x128>
ffffffffc02023fe:	00004617          	auipc	a2,0x4
ffffffffc0202402:	ef260613          	addi	a2,a2,-270 # ffffffffc02062f0 <commands+0x858>
ffffffffc0202406:	12000593          	li	a1,288
ffffffffc020240a:	00004517          	auipc	a0,0x4
ffffffffc020240e:	3ae50513          	addi	a0,a0,942 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0202412:	87cfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202416:	00004697          	auipc	a3,0x4
ffffffffc020241a:	3e268693          	addi	a3,a3,994 # ffffffffc02067f8 <default_pmm_manager+0x158>
ffffffffc020241e:	00004617          	auipc	a2,0x4
ffffffffc0202422:	ed260613          	addi	a2,a2,-302 # ffffffffc02062f0 <commands+0x858>
ffffffffc0202426:	12100593          	li	a1,289
ffffffffc020242a:	00004517          	auipc	a0,0x4
ffffffffc020242e:	38e50513          	addi	a0,a0,910 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0202432:	85cfe0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202436:	b53ff0ef          	jal	ra,ffffffffc0201f88 <pa2page.part.0>

ffffffffc020243a <exit_range>:
{
ffffffffc020243a:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020243c:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202440:	fc86                	sd	ra,120(sp)
ffffffffc0202442:	f8a2                	sd	s0,112(sp)
ffffffffc0202444:	f4a6                	sd	s1,104(sp)
ffffffffc0202446:	f0ca                	sd	s2,96(sp)
ffffffffc0202448:	ecce                	sd	s3,88(sp)
ffffffffc020244a:	e8d2                	sd	s4,80(sp)
ffffffffc020244c:	e4d6                	sd	s5,72(sp)
ffffffffc020244e:	e0da                	sd	s6,64(sp)
ffffffffc0202450:	fc5e                	sd	s7,56(sp)
ffffffffc0202452:	f862                	sd	s8,48(sp)
ffffffffc0202454:	f466                	sd	s9,40(sp)
ffffffffc0202456:	f06a                	sd	s10,32(sp)
ffffffffc0202458:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020245a:	17d2                	slli	a5,a5,0x34
ffffffffc020245c:	20079a63          	bnez	a5,ffffffffc0202670 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc0202460:	002007b7          	lui	a5,0x200
ffffffffc0202464:	24f5e463          	bltu	a1,a5,ffffffffc02026ac <exit_range+0x272>
ffffffffc0202468:	8ab2                	mv	s5,a2
ffffffffc020246a:	24c5f163          	bgeu	a1,a2,ffffffffc02026ac <exit_range+0x272>
ffffffffc020246e:	4785                	li	a5,1
ffffffffc0202470:	07fe                	slli	a5,a5,0x1f
ffffffffc0202472:	22c7ed63          	bltu	a5,a2,ffffffffc02026ac <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202476:	c00009b7          	lui	s3,0xc0000
ffffffffc020247a:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020247e:	ffe00937          	lui	s2,0xffe00
ffffffffc0202482:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc0202486:	5cfd                	li	s9,-1
ffffffffc0202488:	8c2a                	mv	s8,a0
ffffffffc020248a:	0125f933          	and	s2,a1,s2
ffffffffc020248e:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc0202490:	000a8d17          	auipc	s10,0xa8
ffffffffc0202494:	240d0d13          	addi	s10,s10,576 # ffffffffc02aa6d0 <npage>
    return KADDR(page2pa(page));
ffffffffc0202498:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc020249c:	000a8717          	auipc	a4,0xa8
ffffffffc02024a0:	23c70713          	addi	a4,a4,572 # ffffffffc02aa6d8 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc02024a4:	000a8d97          	auipc	s11,0xa8
ffffffffc02024a8:	23cd8d93          	addi	s11,s11,572 # ffffffffc02aa6e0 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02024ac:	c0000437          	lui	s0,0xc0000
ffffffffc02024b0:	944e                	add	s0,s0,s3
ffffffffc02024b2:	8079                	srli	s0,s0,0x1e
ffffffffc02024b4:	1ff47413          	andi	s0,s0,511
ffffffffc02024b8:	040e                	slli	s0,s0,0x3
ffffffffc02024ba:	9462                	add	s0,s0,s8
ffffffffc02024bc:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ee0>
        if (pde1 & PTE_V)
ffffffffc02024c0:	001a7793          	andi	a5,s4,1
ffffffffc02024c4:	eb99                	bnez	a5,ffffffffc02024da <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc02024c6:	12098463          	beqz	s3,ffffffffc02025ee <exit_range+0x1b4>
ffffffffc02024ca:	400007b7          	lui	a5,0x40000
ffffffffc02024ce:	97ce                	add	a5,a5,s3
ffffffffc02024d0:	894e                	mv	s2,s3
ffffffffc02024d2:	1159fe63          	bgeu	s3,s5,ffffffffc02025ee <exit_range+0x1b4>
ffffffffc02024d6:	89be                	mv	s3,a5
ffffffffc02024d8:	bfd1                	j	ffffffffc02024ac <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc02024da:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024de:	0a0a                	slli	s4,s4,0x2
ffffffffc02024e0:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc02024e4:	1cfa7263          	bgeu	s4,a5,ffffffffc02026a8 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02024e8:	fff80637          	lui	a2,0xfff80
ffffffffc02024ec:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc02024ee:	000806b7          	lui	a3,0x80
ffffffffc02024f2:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02024f4:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02024f8:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02024fa:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02024fc:	18f5fa63          	bgeu	a1,a5,ffffffffc0202690 <exit_range+0x256>
ffffffffc0202500:	000a8817          	auipc	a6,0xa8
ffffffffc0202504:	1e880813          	addi	a6,a6,488 # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc0202508:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc020250c:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc020250e:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc0202512:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc0202514:	00080337          	lui	t1,0x80
ffffffffc0202518:	6885                	lui	a7,0x1
ffffffffc020251a:	a819                	j	ffffffffc0202530 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc020251c:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc020251e:	002007b7          	lui	a5,0x200
ffffffffc0202522:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202524:	08090c63          	beqz	s2,ffffffffc02025bc <exit_range+0x182>
ffffffffc0202528:	09397a63          	bgeu	s2,s3,ffffffffc02025bc <exit_range+0x182>
ffffffffc020252c:	0f597063          	bgeu	s2,s5,ffffffffc020260c <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc0202530:	01595493          	srli	s1,s2,0x15
ffffffffc0202534:	1ff4f493          	andi	s1,s1,511
ffffffffc0202538:	048e                	slli	s1,s1,0x3
ffffffffc020253a:	94da                	add	s1,s1,s6
ffffffffc020253c:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc020253e:	0017f693          	andi	a3,a5,1
ffffffffc0202542:	dee9                	beqz	a3,ffffffffc020251c <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc0202544:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202548:	078a                	slli	a5,a5,0x2
ffffffffc020254a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020254c:	14b7fe63          	bgeu	a5,a1,ffffffffc02026a8 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202550:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc0202552:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc0202556:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc020255a:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020255e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202560:	12bef863          	bgeu	t4,a1,ffffffffc0202690 <exit_range+0x256>
ffffffffc0202564:	00083783          	ld	a5,0(a6)
ffffffffc0202568:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020256a:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc020256e:	629c                	ld	a5,0(a3)
ffffffffc0202570:	8b85                	andi	a5,a5,1
ffffffffc0202572:	f7d5                	bnez	a5,ffffffffc020251e <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202574:	06a1                	addi	a3,a3,8
ffffffffc0202576:	fed59ce3          	bne	a1,a3,ffffffffc020256e <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc020257a:	631c                	ld	a5,0(a4)
ffffffffc020257c:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020257e:	100027f3          	csrr	a5,sstatus
ffffffffc0202582:	8b89                	andi	a5,a5,2
ffffffffc0202584:	e7d9                	bnez	a5,ffffffffc0202612 <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc0202586:	000db783          	ld	a5,0(s11)
ffffffffc020258a:	4585                	li	a1,1
ffffffffc020258c:	e032                	sd	a2,0(sp)
ffffffffc020258e:	739c                	ld	a5,32(a5)
ffffffffc0202590:	9782                	jalr	a5
    if (flag)
ffffffffc0202592:	6602                	ld	a2,0(sp)
ffffffffc0202594:	000a8817          	auipc	a6,0xa8
ffffffffc0202598:	15480813          	addi	a6,a6,340 # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc020259c:	fff80e37          	lui	t3,0xfff80
ffffffffc02025a0:	00080337          	lui	t1,0x80
ffffffffc02025a4:	6885                	lui	a7,0x1
ffffffffc02025a6:	000a8717          	auipc	a4,0xa8
ffffffffc02025aa:	13270713          	addi	a4,a4,306 # ffffffffc02aa6d8 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02025ae:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc02025b2:	002007b7          	lui	a5,0x200
ffffffffc02025b6:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02025b8:	f60918e3          	bnez	s2,ffffffffc0202528 <exit_range+0xee>
            if (free_pd0)
ffffffffc02025bc:	f00b85e3          	beqz	s7,ffffffffc02024c6 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc02025c0:	000d3783          	ld	a5,0(s10)
ffffffffc02025c4:	0efa7263          	bgeu	s4,a5,ffffffffc02026a8 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02025c8:	6308                	ld	a0,0(a4)
ffffffffc02025ca:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02025cc:	100027f3          	csrr	a5,sstatus
ffffffffc02025d0:	8b89                	andi	a5,a5,2
ffffffffc02025d2:	efad                	bnez	a5,ffffffffc020264c <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc02025d4:	000db783          	ld	a5,0(s11)
ffffffffc02025d8:	4585                	li	a1,1
ffffffffc02025da:	739c                	ld	a5,32(a5)
ffffffffc02025dc:	9782                	jalr	a5
ffffffffc02025de:	000a8717          	auipc	a4,0xa8
ffffffffc02025e2:	0fa70713          	addi	a4,a4,250 # ffffffffc02aa6d8 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02025e6:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc02025ea:	ee0990e3          	bnez	s3,ffffffffc02024ca <exit_range+0x90>
}
ffffffffc02025ee:	70e6                	ld	ra,120(sp)
ffffffffc02025f0:	7446                	ld	s0,112(sp)
ffffffffc02025f2:	74a6                	ld	s1,104(sp)
ffffffffc02025f4:	7906                	ld	s2,96(sp)
ffffffffc02025f6:	69e6                	ld	s3,88(sp)
ffffffffc02025f8:	6a46                	ld	s4,80(sp)
ffffffffc02025fa:	6aa6                	ld	s5,72(sp)
ffffffffc02025fc:	6b06                	ld	s6,64(sp)
ffffffffc02025fe:	7be2                	ld	s7,56(sp)
ffffffffc0202600:	7c42                	ld	s8,48(sp)
ffffffffc0202602:	7ca2                	ld	s9,40(sp)
ffffffffc0202604:	7d02                	ld	s10,32(sp)
ffffffffc0202606:	6de2                	ld	s11,24(sp)
ffffffffc0202608:	6109                	addi	sp,sp,128
ffffffffc020260a:	8082                	ret
            if (free_pd0)
ffffffffc020260c:	ea0b8fe3          	beqz	s7,ffffffffc02024ca <exit_range+0x90>
ffffffffc0202610:	bf45                	j	ffffffffc02025c0 <exit_range+0x186>
ffffffffc0202612:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0202614:	e42a                	sd	a0,8(sp)
ffffffffc0202616:	b9efe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020261a:	000db783          	ld	a5,0(s11)
ffffffffc020261e:	6522                	ld	a0,8(sp)
ffffffffc0202620:	4585                	li	a1,1
ffffffffc0202622:	739c                	ld	a5,32(a5)
ffffffffc0202624:	9782                	jalr	a5
        intr_enable();
ffffffffc0202626:	b88fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020262a:	6602                	ld	a2,0(sp)
ffffffffc020262c:	000a8717          	auipc	a4,0xa8
ffffffffc0202630:	0ac70713          	addi	a4,a4,172 # ffffffffc02aa6d8 <pages>
ffffffffc0202634:	6885                	lui	a7,0x1
ffffffffc0202636:	00080337          	lui	t1,0x80
ffffffffc020263a:	fff80e37          	lui	t3,0xfff80
ffffffffc020263e:	000a8817          	auipc	a6,0xa8
ffffffffc0202642:	0aa80813          	addi	a6,a6,170 # ffffffffc02aa6e8 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202646:	0004b023          	sd	zero,0(s1)
ffffffffc020264a:	b7a5                	j	ffffffffc02025b2 <exit_range+0x178>
ffffffffc020264c:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc020264e:	b66fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202652:	000db783          	ld	a5,0(s11)
ffffffffc0202656:	6502                	ld	a0,0(sp)
ffffffffc0202658:	4585                	li	a1,1
ffffffffc020265a:	739c                	ld	a5,32(a5)
ffffffffc020265c:	9782                	jalr	a5
        intr_enable();
ffffffffc020265e:	b50fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202662:	000a8717          	auipc	a4,0xa8
ffffffffc0202666:	07670713          	addi	a4,a4,118 # ffffffffc02aa6d8 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020266a:	00043023          	sd	zero,0(s0)
ffffffffc020266e:	bfb5                	j	ffffffffc02025ea <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202670:	00004697          	auipc	a3,0x4
ffffffffc0202674:	15868693          	addi	a3,a3,344 # ffffffffc02067c8 <default_pmm_manager+0x128>
ffffffffc0202678:	00004617          	auipc	a2,0x4
ffffffffc020267c:	c7860613          	addi	a2,a2,-904 # ffffffffc02062f0 <commands+0x858>
ffffffffc0202680:	13500593          	li	a1,309
ffffffffc0202684:	00004517          	auipc	a0,0x4
ffffffffc0202688:	13450513          	addi	a0,a0,308 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc020268c:	e03fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202690:	00004617          	auipc	a2,0x4
ffffffffc0202694:	bb860613          	addi	a2,a2,-1096 # ffffffffc0206248 <commands+0x7b0>
ffffffffc0202698:	07100593          	li	a1,113
ffffffffc020269c:	00004517          	auipc	a0,0x4
ffffffffc02026a0:	bd450513          	addi	a0,a0,-1068 # ffffffffc0206270 <commands+0x7d8>
ffffffffc02026a4:	debfd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02026a8:	8e1ff0ef          	jal	ra,ffffffffc0201f88 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02026ac:	00004697          	auipc	a3,0x4
ffffffffc02026b0:	14c68693          	addi	a3,a3,332 # ffffffffc02067f8 <default_pmm_manager+0x158>
ffffffffc02026b4:	00004617          	auipc	a2,0x4
ffffffffc02026b8:	c3c60613          	addi	a2,a2,-964 # ffffffffc02062f0 <commands+0x858>
ffffffffc02026bc:	13600593          	li	a1,310
ffffffffc02026c0:	00004517          	auipc	a0,0x4
ffffffffc02026c4:	0f850513          	addi	a0,a0,248 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02026c8:	dc7fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02026cc <page_remove>:
{
ffffffffc02026cc:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02026ce:	4601                	li	a2,0
{
ffffffffc02026d0:	ec26                	sd	s1,24(sp)
ffffffffc02026d2:	f406                	sd	ra,40(sp)
ffffffffc02026d4:	f022                	sd	s0,32(sp)
ffffffffc02026d6:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02026d8:	9a1ff0ef          	jal	ra,ffffffffc0202078 <get_pte>
    if (ptep != NULL)
ffffffffc02026dc:	c511                	beqz	a0,ffffffffc02026e8 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc02026de:	611c                	ld	a5,0(a0)
ffffffffc02026e0:	842a                	mv	s0,a0
ffffffffc02026e2:	0017f713          	andi	a4,a5,1
ffffffffc02026e6:	e711                	bnez	a4,ffffffffc02026f2 <page_remove+0x26>
}
ffffffffc02026e8:	70a2                	ld	ra,40(sp)
ffffffffc02026ea:	7402                	ld	s0,32(sp)
ffffffffc02026ec:	64e2                	ld	s1,24(sp)
ffffffffc02026ee:	6145                	addi	sp,sp,48
ffffffffc02026f0:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02026f2:	078a                	slli	a5,a5,0x2
ffffffffc02026f4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026f6:	000a8717          	auipc	a4,0xa8
ffffffffc02026fa:	fda73703          	ld	a4,-38(a4) # ffffffffc02aa6d0 <npage>
ffffffffc02026fe:	06e7f363          	bgeu	a5,a4,ffffffffc0202764 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0202702:	fff80537          	lui	a0,0xfff80
ffffffffc0202706:	97aa                	add	a5,a5,a0
ffffffffc0202708:	079a                	slli	a5,a5,0x6
ffffffffc020270a:	000a8517          	auipc	a0,0xa8
ffffffffc020270e:	fce53503          	ld	a0,-50(a0) # ffffffffc02aa6d8 <pages>
ffffffffc0202712:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202714:	411c                	lw	a5,0(a0)
ffffffffc0202716:	fff7871b          	addiw	a4,a5,-1
ffffffffc020271a:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020271c:	cb11                	beqz	a4,ffffffffc0202730 <page_remove+0x64>
        *ptep = 0;
ffffffffc020271e:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202722:	12048073          	sfence.vma	s1
}
ffffffffc0202726:	70a2                	ld	ra,40(sp)
ffffffffc0202728:	7402                	ld	s0,32(sp)
ffffffffc020272a:	64e2                	ld	s1,24(sp)
ffffffffc020272c:	6145                	addi	sp,sp,48
ffffffffc020272e:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202730:	100027f3          	csrr	a5,sstatus
ffffffffc0202734:	8b89                	andi	a5,a5,2
ffffffffc0202736:	eb89                	bnez	a5,ffffffffc0202748 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202738:	000a8797          	auipc	a5,0xa8
ffffffffc020273c:	fa87b783          	ld	a5,-88(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0202740:	739c                	ld	a5,32(a5)
ffffffffc0202742:	4585                	li	a1,1
ffffffffc0202744:	9782                	jalr	a5
    if (flag)
ffffffffc0202746:	bfe1                	j	ffffffffc020271e <page_remove+0x52>
        intr_disable();
ffffffffc0202748:	e42a                	sd	a0,8(sp)
ffffffffc020274a:	a6afe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020274e:	000a8797          	auipc	a5,0xa8
ffffffffc0202752:	f927b783          	ld	a5,-110(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0202756:	739c                	ld	a5,32(a5)
ffffffffc0202758:	6522                	ld	a0,8(sp)
ffffffffc020275a:	4585                	li	a1,1
ffffffffc020275c:	9782                	jalr	a5
        intr_enable();
ffffffffc020275e:	a50fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202762:	bf75                	j	ffffffffc020271e <page_remove+0x52>
ffffffffc0202764:	825ff0ef          	jal	ra,ffffffffc0201f88 <pa2page.part.0>

ffffffffc0202768 <page_insert>:
{
ffffffffc0202768:	7139                	addi	sp,sp,-64
ffffffffc020276a:	e852                	sd	s4,16(sp)
ffffffffc020276c:	8a32                	mv	s4,a2
ffffffffc020276e:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202770:	4605                	li	a2,1
{
ffffffffc0202772:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202774:	85d2                	mv	a1,s4
{
ffffffffc0202776:	f426                	sd	s1,40(sp)
ffffffffc0202778:	fc06                	sd	ra,56(sp)
ffffffffc020277a:	f04a                	sd	s2,32(sp)
ffffffffc020277c:	ec4e                	sd	s3,24(sp)
ffffffffc020277e:	e456                	sd	s5,8(sp)
ffffffffc0202780:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202782:	8f7ff0ef          	jal	ra,ffffffffc0202078 <get_pte>
    if (ptep == NULL)
ffffffffc0202786:	c961                	beqz	a0,ffffffffc0202856 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202788:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc020278a:	611c                	ld	a5,0(a0)
ffffffffc020278c:	89aa                	mv	s3,a0
ffffffffc020278e:	0016871b          	addiw	a4,a3,1
ffffffffc0202792:	c018                	sw	a4,0(s0)
ffffffffc0202794:	0017f713          	andi	a4,a5,1
ffffffffc0202798:	ef05                	bnez	a4,ffffffffc02027d0 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc020279a:	000a8717          	auipc	a4,0xa8
ffffffffc020279e:	f3e73703          	ld	a4,-194(a4) # ffffffffc02aa6d8 <pages>
ffffffffc02027a2:	8c19                	sub	s0,s0,a4
ffffffffc02027a4:	000807b7          	lui	a5,0x80
ffffffffc02027a8:	8419                	srai	s0,s0,0x6
ffffffffc02027aa:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02027ac:	042a                	slli	s0,s0,0xa
ffffffffc02027ae:	8cc1                	or	s1,s1,s0
ffffffffc02027b0:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02027b4:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ee0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027b8:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02027bc:	4501                	li	a0,0
}
ffffffffc02027be:	70e2                	ld	ra,56(sp)
ffffffffc02027c0:	7442                	ld	s0,48(sp)
ffffffffc02027c2:	74a2                	ld	s1,40(sp)
ffffffffc02027c4:	7902                	ld	s2,32(sp)
ffffffffc02027c6:	69e2                	ld	s3,24(sp)
ffffffffc02027c8:	6a42                	ld	s4,16(sp)
ffffffffc02027ca:	6aa2                	ld	s5,8(sp)
ffffffffc02027cc:	6121                	addi	sp,sp,64
ffffffffc02027ce:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02027d0:	078a                	slli	a5,a5,0x2
ffffffffc02027d2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02027d4:	000a8717          	auipc	a4,0xa8
ffffffffc02027d8:	efc73703          	ld	a4,-260(a4) # ffffffffc02aa6d0 <npage>
ffffffffc02027dc:	06e7ff63          	bgeu	a5,a4,ffffffffc020285a <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02027e0:	000a8a97          	auipc	s5,0xa8
ffffffffc02027e4:	ef8a8a93          	addi	s5,s5,-264 # ffffffffc02aa6d8 <pages>
ffffffffc02027e8:	000ab703          	ld	a4,0(s5)
ffffffffc02027ec:	fff80937          	lui	s2,0xfff80
ffffffffc02027f0:	993e                	add	s2,s2,a5
ffffffffc02027f2:	091a                	slli	s2,s2,0x6
ffffffffc02027f4:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02027f6:	01240c63          	beq	s0,s2,ffffffffc020280e <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02027fa:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcd58f4>
ffffffffc02027fe:	fff7869b          	addiw	a3,a5,-1
ffffffffc0202802:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc0202806:	c691                	beqz	a3,ffffffffc0202812 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202808:	120a0073          	sfence.vma	s4
}
ffffffffc020280c:	bf59                	j	ffffffffc02027a2 <page_insert+0x3a>
ffffffffc020280e:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202810:	bf49                	j	ffffffffc02027a2 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202812:	100027f3          	csrr	a5,sstatus
ffffffffc0202816:	8b89                	andi	a5,a5,2
ffffffffc0202818:	ef91                	bnez	a5,ffffffffc0202834 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc020281a:	000a8797          	auipc	a5,0xa8
ffffffffc020281e:	ec67b783          	ld	a5,-314(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0202822:	739c                	ld	a5,32(a5)
ffffffffc0202824:	4585                	li	a1,1
ffffffffc0202826:	854a                	mv	a0,s2
ffffffffc0202828:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020282a:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020282e:	120a0073          	sfence.vma	s4
ffffffffc0202832:	bf85                	j	ffffffffc02027a2 <page_insert+0x3a>
        intr_disable();
ffffffffc0202834:	980fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202838:	000a8797          	auipc	a5,0xa8
ffffffffc020283c:	ea87b783          	ld	a5,-344(a5) # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0202840:	739c                	ld	a5,32(a5)
ffffffffc0202842:	4585                	li	a1,1
ffffffffc0202844:	854a                	mv	a0,s2
ffffffffc0202846:	9782                	jalr	a5
        intr_enable();
ffffffffc0202848:	966fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020284c:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202850:	120a0073          	sfence.vma	s4
ffffffffc0202854:	b7b9                	j	ffffffffc02027a2 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202856:	5571                	li	a0,-4
ffffffffc0202858:	b79d                	j	ffffffffc02027be <page_insert+0x56>
ffffffffc020285a:	f2eff0ef          	jal	ra,ffffffffc0201f88 <pa2page.part.0>

ffffffffc020285e <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020285e:	00004797          	auipc	a5,0x4
ffffffffc0202862:	e4278793          	addi	a5,a5,-446 # ffffffffc02066a0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202866:	638c                	ld	a1,0(a5)
{
ffffffffc0202868:	7159                	addi	sp,sp,-112
ffffffffc020286a:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020286c:	00004517          	auipc	a0,0x4
ffffffffc0202870:	fa450513          	addi	a0,a0,-92 # ffffffffc0206810 <default_pmm_manager+0x170>
    pmm_manager = &default_pmm_manager;
ffffffffc0202874:	000a8b17          	auipc	s6,0xa8
ffffffffc0202878:	e6cb0b13          	addi	s6,s6,-404 # ffffffffc02aa6e0 <pmm_manager>
{
ffffffffc020287c:	f486                	sd	ra,104(sp)
ffffffffc020287e:	e8ca                	sd	s2,80(sp)
ffffffffc0202880:	e4ce                	sd	s3,72(sp)
ffffffffc0202882:	f0a2                	sd	s0,96(sp)
ffffffffc0202884:	eca6                	sd	s1,88(sp)
ffffffffc0202886:	e0d2                	sd	s4,64(sp)
ffffffffc0202888:	fc56                	sd	s5,56(sp)
ffffffffc020288a:	f45e                	sd	s7,40(sp)
ffffffffc020288c:	f062                	sd	s8,32(sp)
ffffffffc020288e:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202890:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202894:	901fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202898:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020289c:	000a8997          	auipc	s3,0xa8
ffffffffc02028a0:	e4c98993          	addi	s3,s3,-436 # ffffffffc02aa6e8 <va_pa_offset>
    pmm_manager->init();
ffffffffc02028a4:	679c                	ld	a5,8(a5)
ffffffffc02028a6:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02028a8:	57f5                	li	a5,-3
ffffffffc02028aa:	07fa                	slli	a5,a5,0x1e
ffffffffc02028ac:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02028b0:	8eafe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc02028b4:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02028b6:	8eefe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc02028ba:	200505e3          	beqz	a0,ffffffffc02032c4 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02028be:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02028c0:	00004517          	auipc	a0,0x4
ffffffffc02028c4:	f8850513          	addi	a0,a0,-120 # ffffffffc0206848 <default_pmm_manager+0x1a8>
ffffffffc02028c8:	8cdfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02028cc:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02028d0:	fff40693          	addi	a3,s0,-1
ffffffffc02028d4:	864a                	mv	a2,s2
ffffffffc02028d6:	85a6                	mv	a1,s1
ffffffffc02028d8:	00004517          	auipc	a0,0x4
ffffffffc02028dc:	f8850513          	addi	a0,a0,-120 # ffffffffc0206860 <default_pmm_manager+0x1c0>
ffffffffc02028e0:	8b5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02028e4:	c8000737          	lui	a4,0xc8000
ffffffffc02028e8:	87a2                	mv	a5,s0
ffffffffc02028ea:	54876163          	bltu	a4,s0,ffffffffc0202e2c <pmm_init+0x5ce>
ffffffffc02028ee:	757d                	lui	a0,0xfffff
ffffffffc02028f0:	000a9617          	auipc	a2,0xa9
ffffffffc02028f4:	e1b60613          	addi	a2,a2,-485 # ffffffffc02ab70b <end+0xfff>
ffffffffc02028f8:	8e69                	and	a2,a2,a0
ffffffffc02028fa:	000a8497          	auipc	s1,0xa8
ffffffffc02028fe:	dd648493          	addi	s1,s1,-554 # ffffffffc02aa6d0 <npage>
ffffffffc0202902:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202906:	000a8b97          	auipc	s7,0xa8
ffffffffc020290a:	dd2b8b93          	addi	s7,s7,-558 # ffffffffc02aa6d8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020290e:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202910:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202914:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202918:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020291a:	02f50863          	beq	a0,a5,ffffffffc020294a <pmm_init+0xec>
ffffffffc020291e:	4781                	li	a5,0
ffffffffc0202920:	4585                	li	a1,1
ffffffffc0202922:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202926:	00679513          	slli	a0,a5,0x6
ffffffffc020292a:	9532                	add	a0,a0,a2
ffffffffc020292c:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd548fc>
ffffffffc0202930:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202934:	6088                	ld	a0,0(s1)
ffffffffc0202936:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202938:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020293c:	00d50733          	add	a4,a0,a3
ffffffffc0202940:	fee7e3e3          	bltu	a5,a4,ffffffffc0202926 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202944:	071a                	slli	a4,a4,0x6
ffffffffc0202946:	00e606b3          	add	a3,a2,a4
ffffffffc020294a:	c02007b7          	lui	a5,0xc0200
ffffffffc020294e:	2ef6ece3          	bltu	a3,a5,ffffffffc0203446 <pmm_init+0xbe8>
ffffffffc0202952:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202956:	77fd                	lui	a5,0xfffff
ffffffffc0202958:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020295a:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc020295c:	5086eb63          	bltu	a3,s0,ffffffffc0202e72 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202960:	00004517          	auipc	a0,0x4
ffffffffc0202964:	f2850513          	addi	a0,a0,-216 # ffffffffc0206888 <default_pmm_manager+0x1e8>
ffffffffc0202968:	82dfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc020296c:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202970:	000a8917          	auipc	s2,0xa8
ffffffffc0202974:	d5890913          	addi	s2,s2,-680 # ffffffffc02aa6c8 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202978:	7b9c                	ld	a5,48(a5)
ffffffffc020297a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020297c:	00004517          	auipc	a0,0x4
ffffffffc0202980:	f2450513          	addi	a0,a0,-220 # ffffffffc02068a0 <default_pmm_manager+0x200>
ffffffffc0202984:	811fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202988:	00007697          	auipc	a3,0x7
ffffffffc020298c:	67868693          	addi	a3,a3,1656 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0202990:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202994:	c02007b7          	lui	a5,0xc0200
ffffffffc0202998:	28f6ebe3          	bltu	a3,a5,ffffffffc020342e <pmm_init+0xbd0>
ffffffffc020299c:	0009b783          	ld	a5,0(s3)
ffffffffc02029a0:	8e9d                	sub	a3,a3,a5
ffffffffc02029a2:	000a8797          	auipc	a5,0xa8
ffffffffc02029a6:	d0d7bf23          	sd	a3,-738(a5) # ffffffffc02aa6c0 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02029aa:	100027f3          	csrr	a5,sstatus
ffffffffc02029ae:	8b89                	andi	a5,a5,2
ffffffffc02029b0:	4a079763          	bnez	a5,ffffffffc0202e5e <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc02029b4:	000b3783          	ld	a5,0(s6)
ffffffffc02029b8:	779c                	ld	a5,40(a5)
ffffffffc02029ba:	9782                	jalr	a5
ffffffffc02029bc:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02029be:	6098                	ld	a4,0(s1)
ffffffffc02029c0:	c80007b7          	lui	a5,0xc8000
ffffffffc02029c4:	83b1                	srli	a5,a5,0xc
ffffffffc02029c6:	66e7e363          	bltu	a5,a4,ffffffffc020302c <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02029ca:	00093503          	ld	a0,0(s2)
ffffffffc02029ce:	62050f63          	beqz	a0,ffffffffc020300c <pmm_init+0x7ae>
ffffffffc02029d2:	03451793          	slli	a5,a0,0x34
ffffffffc02029d6:	62079b63          	bnez	a5,ffffffffc020300c <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02029da:	4601                	li	a2,0
ffffffffc02029dc:	4581                	li	a1,0
ffffffffc02029de:	8c3ff0ef          	jal	ra,ffffffffc02022a0 <get_page>
ffffffffc02029e2:	60051563          	bnez	a0,ffffffffc0202fec <pmm_init+0x78e>
ffffffffc02029e6:	100027f3          	csrr	a5,sstatus
ffffffffc02029ea:	8b89                	andi	a5,a5,2
ffffffffc02029ec:	44079e63          	bnez	a5,ffffffffc0202e48 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02029f0:	000b3783          	ld	a5,0(s6)
ffffffffc02029f4:	4505                	li	a0,1
ffffffffc02029f6:	6f9c                	ld	a5,24(a5)
ffffffffc02029f8:	9782                	jalr	a5
ffffffffc02029fa:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02029fc:	00093503          	ld	a0,0(s2)
ffffffffc0202a00:	4681                	li	a3,0
ffffffffc0202a02:	4601                	li	a2,0
ffffffffc0202a04:	85d2                	mv	a1,s4
ffffffffc0202a06:	d63ff0ef          	jal	ra,ffffffffc0202768 <page_insert>
ffffffffc0202a0a:	26051ae3          	bnez	a0,ffffffffc020347e <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202a0e:	00093503          	ld	a0,0(s2)
ffffffffc0202a12:	4601                	li	a2,0
ffffffffc0202a14:	4581                	li	a1,0
ffffffffc0202a16:	e62ff0ef          	jal	ra,ffffffffc0202078 <get_pte>
ffffffffc0202a1a:	240502e3          	beqz	a0,ffffffffc020345e <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a1e:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a20:	0017f713          	andi	a4,a5,1
ffffffffc0202a24:	5a070263          	beqz	a4,ffffffffc0202fc8 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202a28:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a2a:	078a                	slli	a5,a5,0x2
ffffffffc0202a2c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a2e:	58e7fb63          	bgeu	a5,a4,ffffffffc0202fc4 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a32:	000bb683          	ld	a3,0(s7)
ffffffffc0202a36:	fff80637          	lui	a2,0xfff80
ffffffffc0202a3a:	97b2                	add	a5,a5,a2
ffffffffc0202a3c:	079a                	slli	a5,a5,0x6
ffffffffc0202a3e:	97b6                	add	a5,a5,a3
ffffffffc0202a40:	14fa17e3          	bne	s4,a5,ffffffffc020338e <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202a44:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
ffffffffc0202a48:	4785                	li	a5,1
ffffffffc0202a4a:	12f692e3          	bne	a3,a5,ffffffffc020336e <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202a4e:	00093503          	ld	a0,0(s2)
ffffffffc0202a52:	77fd                	lui	a5,0xfffff
ffffffffc0202a54:	6114                	ld	a3,0(a0)
ffffffffc0202a56:	068a                	slli	a3,a3,0x2
ffffffffc0202a58:	8efd                	and	a3,a3,a5
ffffffffc0202a5a:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202a5e:	0ee67ce3          	bgeu	a2,a4,ffffffffc0203356 <pmm_init+0xaf8>
ffffffffc0202a62:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202a66:	96e2                	add	a3,a3,s8
ffffffffc0202a68:	0006ba83          	ld	s5,0(a3)
ffffffffc0202a6c:	0a8a                	slli	s5,s5,0x2
ffffffffc0202a6e:	00fafab3          	and	s5,s5,a5
ffffffffc0202a72:	00cad793          	srli	a5,s5,0xc
ffffffffc0202a76:	0ce7f3e3          	bgeu	a5,a4,ffffffffc020333c <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a7a:	4601                	li	a2,0
ffffffffc0202a7c:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202a7e:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a80:	df8ff0ef          	jal	ra,ffffffffc0202078 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202a84:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a86:	55551363          	bne	a0,s5,ffffffffc0202fcc <pmm_init+0x76e>
ffffffffc0202a8a:	100027f3          	csrr	a5,sstatus
ffffffffc0202a8e:	8b89                	andi	a5,a5,2
ffffffffc0202a90:	3a079163          	bnez	a5,ffffffffc0202e32 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202a94:	000b3783          	ld	a5,0(s6)
ffffffffc0202a98:	4505                	li	a0,1
ffffffffc0202a9a:	6f9c                	ld	a5,24(a5)
ffffffffc0202a9c:	9782                	jalr	a5
ffffffffc0202a9e:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202aa0:	00093503          	ld	a0,0(s2)
ffffffffc0202aa4:	46d1                	li	a3,20
ffffffffc0202aa6:	6605                	lui	a2,0x1
ffffffffc0202aa8:	85e2                	mv	a1,s8
ffffffffc0202aaa:	cbfff0ef          	jal	ra,ffffffffc0202768 <page_insert>
ffffffffc0202aae:	060517e3          	bnez	a0,ffffffffc020331c <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202ab2:	00093503          	ld	a0,0(s2)
ffffffffc0202ab6:	4601                	li	a2,0
ffffffffc0202ab8:	6585                	lui	a1,0x1
ffffffffc0202aba:	dbeff0ef          	jal	ra,ffffffffc0202078 <get_pte>
ffffffffc0202abe:	02050fe3          	beqz	a0,ffffffffc02032fc <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0202ac2:	611c                	ld	a5,0(a0)
ffffffffc0202ac4:	0107f713          	andi	a4,a5,16
ffffffffc0202ac8:	7c070e63          	beqz	a4,ffffffffc02032a4 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202acc:	8b91                	andi	a5,a5,4
ffffffffc0202ace:	7a078b63          	beqz	a5,ffffffffc0203284 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202ad2:	00093503          	ld	a0,0(s2)
ffffffffc0202ad6:	611c                	ld	a5,0(a0)
ffffffffc0202ad8:	8bc1                	andi	a5,a5,16
ffffffffc0202ada:	78078563          	beqz	a5,ffffffffc0203264 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0202ade:	000c2703          	lw	a4,0(s8)
ffffffffc0202ae2:	4785                	li	a5,1
ffffffffc0202ae4:	76f71063          	bne	a4,a5,ffffffffc0203244 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202ae8:	4681                	li	a3,0
ffffffffc0202aea:	6605                	lui	a2,0x1
ffffffffc0202aec:	85d2                	mv	a1,s4
ffffffffc0202aee:	c7bff0ef          	jal	ra,ffffffffc0202768 <page_insert>
ffffffffc0202af2:	72051963          	bnez	a0,ffffffffc0203224 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202af6:	000a2703          	lw	a4,0(s4)
ffffffffc0202afa:	4789                	li	a5,2
ffffffffc0202afc:	70f71463          	bne	a4,a5,ffffffffc0203204 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202b00:	000c2783          	lw	a5,0(s8)
ffffffffc0202b04:	6e079063          	bnez	a5,ffffffffc02031e4 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202b08:	00093503          	ld	a0,0(s2)
ffffffffc0202b0c:	4601                	li	a2,0
ffffffffc0202b0e:	6585                	lui	a1,0x1
ffffffffc0202b10:	d68ff0ef          	jal	ra,ffffffffc0202078 <get_pte>
ffffffffc0202b14:	6a050863          	beqz	a0,ffffffffc02031c4 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202b18:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202b1a:	00177793          	andi	a5,a4,1
ffffffffc0202b1e:	4a078563          	beqz	a5,ffffffffc0202fc8 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202b22:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202b24:	00271793          	slli	a5,a4,0x2
ffffffffc0202b28:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b2a:	48d7fd63          	bgeu	a5,a3,ffffffffc0202fc4 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b2e:	000bb683          	ld	a3,0(s7)
ffffffffc0202b32:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202b36:	97d6                	add	a5,a5,s5
ffffffffc0202b38:	079a                	slli	a5,a5,0x6
ffffffffc0202b3a:	97b6                	add	a5,a5,a3
ffffffffc0202b3c:	66fa1463          	bne	s4,a5,ffffffffc02031a4 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202b40:	8b41                	andi	a4,a4,16
ffffffffc0202b42:	64071163          	bnez	a4,ffffffffc0203184 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202b46:	00093503          	ld	a0,0(s2)
ffffffffc0202b4a:	4581                	li	a1,0
ffffffffc0202b4c:	b81ff0ef          	jal	ra,ffffffffc02026cc <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202b50:	000a2c83          	lw	s9,0(s4)
ffffffffc0202b54:	4785                	li	a5,1
ffffffffc0202b56:	60fc9763          	bne	s9,a5,ffffffffc0203164 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202b5a:	000c2783          	lw	a5,0(s8)
ffffffffc0202b5e:	5e079363          	bnez	a5,ffffffffc0203144 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202b62:	00093503          	ld	a0,0(s2)
ffffffffc0202b66:	6585                	lui	a1,0x1
ffffffffc0202b68:	b65ff0ef          	jal	ra,ffffffffc02026cc <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202b6c:	000a2783          	lw	a5,0(s4)
ffffffffc0202b70:	52079a63          	bnez	a5,ffffffffc02030a4 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202b74:	000c2783          	lw	a5,0(s8)
ffffffffc0202b78:	50079663          	bnez	a5,ffffffffc0203084 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202b7c:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202b80:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b82:	000a3683          	ld	a3,0(s4)
ffffffffc0202b86:	068a                	slli	a3,a3,0x2
ffffffffc0202b88:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b8a:	42b6fd63          	bgeu	a3,a1,ffffffffc0202fc4 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b8e:	000bb503          	ld	a0,0(s7)
ffffffffc0202b92:	96d6                	add	a3,a3,s5
ffffffffc0202b94:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202b96:	00d507b3          	add	a5,a0,a3
ffffffffc0202b9a:	439c                	lw	a5,0(a5)
ffffffffc0202b9c:	4d979463          	bne	a5,s9,ffffffffc0203064 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202ba0:	8699                	srai	a3,a3,0x6
ffffffffc0202ba2:	00080637          	lui	a2,0x80
ffffffffc0202ba6:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202ba8:	00c69713          	slli	a4,a3,0xc
ffffffffc0202bac:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202bae:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202bb0:	48b77e63          	bgeu	a4,a1,ffffffffc020304c <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202bb4:	0009b703          	ld	a4,0(s3)
ffffffffc0202bb8:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bba:	629c                	ld	a5,0(a3)
ffffffffc0202bbc:	078a                	slli	a5,a5,0x2
ffffffffc0202bbe:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202bc0:	40b7f263          	bgeu	a5,a1,ffffffffc0202fc4 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202bc4:	8f91                	sub	a5,a5,a2
ffffffffc0202bc6:	079a                	slli	a5,a5,0x6
ffffffffc0202bc8:	953e                	add	a0,a0,a5
ffffffffc0202bca:	100027f3          	csrr	a5,sstatus
ffffffffc0202bce:	8b89                	andi	a5,a5,2
ffffffffc0202bd0:	30079963          	bnez	a5,ffffffffc0202ee2 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202bd4:	000b3783          	ld	a5,0(s6)
ffffffffc0202bd8:	4585                	li	a1,1
ffffffffc0202bda:	739c                	ld	a5,32(a5)
ffffffffc0202bdc:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202bde:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202be2:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202be4:	078a                	slli	a5,a5,0x2
ffffffffc0202be6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202be8:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202fc4 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202bec:	000bb503          	ld	a0,0(s7)
ffffffffc0202bf0:	fff80737          	lui	a4,0xfff80
ffffffffc0202bf4:	97ba                	add	a5,a5,a4
ffffffffc0202bf6:	079a                	slli	a5,a5,0x6
ffffffffc0202bf8:	953e                	add	a0,a0,a5
ffffffffc0202bfa:	100027f3          	csrr	a5,sstatus
ffffffffc0202bfe:	8b89                	andi	a5,a5,2
ffffffffc0202c00:	2c079563          	bnez	a5,ffffffffc0202eca <pmm_init+0x66c>
ffffffffc0202c04:	000b3783          	ld	a5,0(s6)
ffffffffc0202c08:	4585                	li	a1,1
ffffffffc0202c0a:	739c                	ld	a5,32(a5)
ffffffffc0202c0c:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202c0e:	00093783          	ld	a5,0(s2)
ffffffffc0202c12:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd548f4>
    asm volatile("sfence.vma");
ffffffffc0202c16:	12000073          	sfence.vma
ffffffffc0202c1a:	100027f3          	csrr	a5,sstatus
ffffffffc0202c1e:	8b89                	andi	a5,a5,2
ffffffffc0202c20:	28079b63          	bnez	a5,ffffffffc0202eb6 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c24:	000b3783          	ld	a5,0(s6)
ffffffffc0202c28:	779c                	ld	a5,40(a5)
ffffffffc0202c2a:	9782                	jalr	a5
ffffffffc0202c2c:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202c2e:	4b441b63          	bne	s0,s4,ffffffffc02030e4 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202c32:	00004517          	auipc	a0,0x4
ffffffffc0202c36:	f9650513          	addi	a0,a0,-106 # ffffffffc0206bc8 <default_pmm_manager+0x528>
ffffffffc0202c3a:	d5afd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202c3e:	100027f3          	csrr	a5,sstatus
ffffffffc0202c42:	8b89                	andi	a5,a5,2
ffffffffc0202c44:	24079f63          	bnez	a5,ffffffffc0202ea2 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202c48:	000b3783          	ld	a5,0(s6)
ffffffffc0202c4c:	779c                	ld	a5,40(a5)
ffffffffc0202c4e:	9782                	jalr	a5
ffffffffc0202c50:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202c52:	6098                	ld	a4,0(s1)
ffffffffc0202c54:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202c58:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202c5a:	00c71793          	slli	a5,a4,0xc
ffffffffc0202c5e:	6a05                	lui	s4,0x1
ffffffffc0202c60:	02f47c63          	bgeu	s0,a5,ffffffffc0202c98 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202c64:	00c45793          	srli	a5,s0,0xc
ffffffffc0202c68:	00093503          	ld	a0,0(s2)
ffffffffc0202c6c:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202f6a <pmm_init+0x70c>
ffffffffc0202c70:	0009b583          	ld	a1,0(s3)
ffffffffc0202c74:	4601                	li	a2,0
ffffffffc0202c76:	95a2                	add	a1,a1,s0
ffffffffc0202c78:	c00ff0ef          	jal	ra,ffffffffc0202078 <get_pte>
ffffffffc0202c7c:	32050463          	beqz	a0,ffffffffc0202fa4 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202c80:	611c                	ld	a5,0(a0)
ffffffffc0202c82:	078a                	slli	a5,a5,0x2
ffffffffc0202c84:	0157f7b3          	and	a5,a5,s5
ffffffffc0202c88:	2e879e63          	bne	a5,s0,ffffffffc0202f84 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202c8c:	6098                	ld	a4,0(s1)
ffffffffc0202c8e:	9452                	add	s0,s0,s4
ffffffffc0202c90:	00c71793          	slli	a5,a4,0xc
ffffffffc0202c94:	fcf468e3          	bltu	s0,a5,ffffffffc0202c64 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202c98:	00093783          	ld	a5,0(s2)
ffffffffc0202c9c:	639c                	ld	a5,0(a5)
ffffffffc0202c9e:	42079363          	bnez	a5,ffffffffc02030c4 <pmm_init+0x866>
ffffffffc0202ca2:	100027f3          	csrr	a5,sstatus
ffffffffc0202ca6:	8b89                	andi	a5,a5,2
ffffffffc0202ca8:	24079963          	bnez	a5,ffffffffc0202efa <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202cac:	000b3783          	ld	a5,0(s6)
ffffffffc0202cb0:	4505                	li	a0,1
ffffffffc0202cb2:	6f9c                	ld	a5,24(a5)
ffffffffc0202cb4:	9782                	jalr	a5
ffffffffc0202cb6:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202cb8:	00093503          	ld	a0,0(s2)
ffffffffc0202cbc:	4699                	li	a3,6
ffffffffc0202cbe:	10000613          	li	a2,256
ffffffffc0202cc2:	85d2                	mv	a1,s4
ffffffffc0202cc4:	aa5ff0ef          	jal	ra,ffffffffc0202768 <page_insert>
ffffffffc0202cc8:	44051e63          	bnez	a0,ffffffffc0203124 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202ccc:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
ffffffffc0202cd0:	4785                	li	a5,1
ffffffffc0202cd2:	42f71963          	bne	a4,a5,ffffffffc0203104 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202cd6:	00093503          	ld	a0,0(s2)
ffffffffc0202cda:	6405                	lui	s0,0x1
ffffffffc0202cdc:	4699                	li	a3,6
ffffffffc0202cde:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8aa8>
ffffffffc0202ce2:	85d2                	mv	a1,s4
ffffffffc0202ce4:	a85ff0ef          	jal	ra,ffffffffc0202768 <page_insert>
ffffffffc0202ce8:	72051363          	bnez	a0,ffffffffc020340e <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202cec:	000a2703          	lw	a4,0(s4)
ffffffffc0202cf0:	4789                	li	a5,2
ffffffffc0202cf2:	6ef71e63          	bne	a4,a5,ffffffffc02033ee <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202cf6:	00004597          	auipc	a1,0x4
ffffffffc0202cfa:	01a58593          	addi	a1,a1,26 # ffffffffc0206d10 <default_pmm_manager+0x670>
ffffffffc0202cfe:	10000513          	li	a0,256
ffffffffc0202d02:	295020ef          	jal	ra,ffffffffc0205796 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202d06:	10040593          	addi	a1,s0,256
ffffffffc0202d0a:	10000513          	li	a0,256
ffffffffc0202d0e:	29b020ef          	jal	ra,ffffffffc02057a8 <strcmp>
ffffffffc0202d12:	6a051e63          	bnez	a0,ffffffffc02033ce <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202d16:	000bb683          	ld	a3,0(s7)
ffffffffc0202d1a:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202d1e:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202d20:	40da06b3          	sub	a3,s4,a3
ffffffffc0202d24:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202d26:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202d28:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202d2a:	8031                	srli	s0,s0,0xc
ffffffffc0202d2c:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202d30:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202d32:	30f77d63          	bgeu	a4,a5,ffffffffc020304c <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202d36:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202d3a:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202d3e:	96be                	add	a3,a3,a5
ffffffffc0202d40:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202d44:	21d020ef          	jal	ra,ffffffffc0205760 <strlen>
ffffffffc0202d48:	66051363          	bnez	a0,ffffffffc02033ae <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202d4c:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202d50:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d52:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd548f4>
ffffffffc0202d56:	068a                	slli	a3,a3,0x2
ffffffffc0202d58:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d5a:	26f6f563          	bgeu	a3,a5,ffffffffc0202fc4 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202d5e:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202d60:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202d62:	2ef47563          	bgeu	s0,a5,ffffffffc020304c <pmm_init+0x7ee>
ffffffffc0202d66:	0009b403          	ld	s0,0(s3)
ffffffffc0202d6a:	9436                	add	s0,s0,a3
ffffffffc0202d6c:	100027f3          	csrr	a5,sstatus
ffffffffc0202d70:	8b89                	andi	a5,a5,2
ffffffffc0202d72:	1e079163          	bnez	a5,ffffffffc0202f54 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202d76:	000b3783          	ld	a5,0(s6)
ffffffffc0202d7a:	4585                	li	a1,1
ffffffffc0202d7c:	8552                	mv	a0,s4
ffffffffc0202d7e:	739c                	ld	a5,32(a5)
ffffffffc0202d80:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d82:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202d84:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d86:	078a                	slli	a5,a5,0x2
ffffffffc0202d88:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d8a:	22e7fd63          	bgeu	a5,a4,ffffffffc0202fc4 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d8e:	000bb503          	ld	a0,0(s7)
ffffffffc0202d92:	fff80737          	lui	a4,0xfff80
ffffffffc0202d96:	97ba                	add	a5,a5,a4
ffffffffc0202d98:	079a                	slli	a5,a5,0x6
ffffffffc0202d9a:	953e                	add	a0,a0,a5
ffffffffc0202d9c:	100027f3          	csrr	a5,sstatus
ffffffffc0202da0:	8b89                	andi	a5,a5,2
ffffffffc0202da2:	18079d63          	bnez	a5,ffffffffc0202f3c <pmm_init+0x6de>
ffffffffc0202da6:	000b3783          	ld	a5,0(s6)
ffffffffc0202daa:	4585                	li	a1,1
ffffffffc0202dac:	739c                	ld	a5,32(a5)
ffffffffc0202dae:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202db0:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202db4:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202db6:	078a                	slli	a5,a5,0x2
ffffffffc0202db8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202dba:	20e7f563          	bgeu	a5,a4,ffffffffc0202fc4 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202dbe:	000bb503          	ld	a0,0(s7)
ffffffffc0202dc2:	fff80737          	lui	a4,0xfff80
ffffffffc0202dc6:	97ba                	add	a5,a5,a4
ffffffffc0202dc8:	079a                	slli	a5,a5,0x6
ffffffffc0202dca:	953e                	add	a0,a0,a5
ffffffffc0202dcc:	100027f3          	csrr	a5,sstatus
ffffffffc0202dd0:	8b89                	andi	a5,a5,2
ffffffffc0202dd2:	14079963          	bnez	a5,ffffffffc0202f24 <pmm_init+0x6c6>
ffffffffc0202dd6:	000b3783          	ld	a5,0(s6)
ffffffffc0202dda:	4585                	li	a1,1
ffffffffc0202ddc:	739c                	ld	a5,32(a5)
ffffffffc0202dde:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202de0:	00093783          	ld	a5,0(s2)
ffffffffc0202de4:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202de8:	12000073          	sfence.vma
ffffffffc0202dec:	100027f3          	csrr	a5,sstatus
ffffffffc0202df0:	8b89                	andi	a5,a5,2
ffffffffc0202df2:	10079f63          	bnez	a5,ffffffffc0202f10 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202df6:	000b3783          	ld	a5,0(s6)
ffffffffc0202dfa:	779c                	ld	a5,40(a5)
ffffffffc0202dfc:	9782                	jalr	a5
ffffffffc0202dfe:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202e00:	4c8c1e63          	bne	s8,s0,ffffffffc02032dc <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202e04:	00004517          	auipc	a0,0x4
ffffffffc0202e08:	f8450513          	addi	a0,a0,-124 # ffffffffc0206d88 <default_pmm_manager+0x6e8>
ffffffffc0202e0c:	b88fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202e10:	7406                	ld	s0,96(sp)
ffffffffc0202e12:	70a6                	ld	ra,104(sp)
ffffffffc0202e14:	64e6                	ld	s1,88(sp)
ffffffffc0202e16:	6946                	ld	s2,80(sp)
ffffffffc0202e18:	69a6                	ld	s3,72(sp)
ffffffffc0202e1a:	6a06                	ld	s4,64(sp)
ffffffffc0202e1c:	7ae2                	ld	s5,56(sp)
ffffffffc0202e1e:	7b42                	ld	s6,48(sp)
ffffffffc0202e20:	7ba2                	ld	s7,40(sp)
ffffffffc0202e22:	7c02                	ld	s8,32(sp)
ffffffffc0202e24:	6ce2                	ld	s9,24(sp)
ffffffffc0202e26:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202e28:	f97fe06f          	j	ffffffffc0201dbe <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202e2c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202e30:	bc7d                	j	ffffffffc02028ee <pmm_init+0x90>
        intr_disable();
ffffffffc0202e32:	b83fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e36:	000b3783          	ld	a5,0(s6)
ffffffffc0202e3a:	4505                	li	a0,1
ffffffffc0202e3c:	6f9c                	ld	a5,24(a5)
ffffffffc0202e3e:	9782                	jalr	a5
ffffffffc0202e40:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202e42:	b6dfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e46:	b9a9                	j	ffffffffc0202aa0 <pmm_init+0x242>
        intr_disable();
ffffffffc0202e48:	b6dfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e4c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e50:	4505                	li	a0,1
ffffffffc0202e52:	6f9c                	ld	a5,24(a5)
ffffffffc0202e54:	9782                	jalr	a5
ffffffffc0202e56:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e58:	b57fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e5c:	b645                	j	ffffffffc02029fc <pmm_init+0x19e>
        intr_disable();
ffffffffc0202e5e:	b57fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e62:	000b3783          	ld	a5,0(s6)
ffffffffc0202e66:	779c                	ld	a5,40(a5)
ffffffffc0202e68:	9782                	jalr	a5
ffffffffc0202e6a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e6c:	b43fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e70:	b6b9                	j	ffffffffc02029be <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202e72:	6705                	lui	a4,0x1
ffffffffc0202e74:	177d                	addi	a4,a4,-1
ffffffffc0202e76:	96ba                	add	a3,a3,a4
ffffffffc0202e78:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202e7a:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202e7e:	14a77363          	bgeu	a4,a0,ffffffffc0202fc4 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202e82:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202e86:	fff80537          	lui	a0,0xfff80
ffffffffc0202e8a:	972a                	add	a4,a4,a0
ffffffffc0202e8c:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202e8e:	8c1d                	sub	s0,s0,a5
ffffffffc0202e90:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202e94:	00c45593          	srli	a1,s0,0xc
ffffffffc0202e98:	9532                	add	a0,a0,a2
ffffffffc0202e9a:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202e9c:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202ea0:	b4c1                	j	ffffffffc0202960 <pmm_init+0x102>
        intr_disable();
ffffffffc0202ea2:	b13fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ea6:	000b3783          	ld	a5,0(s6)
ffffffffc0202eaa:	779c                	ld	a5,40(a5)
ffffffffc0202eac:	9782                	jalr	a5
ffffffffc0202eae:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202eb0:	afffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202eb4:	bb79                	j	ffffffffc0202c52 <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202eb6:	afffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202eba:	000b3783          	ld	a5,0(s6)
ffffffffc0202ebe:	779c                	ld	a5,40(a5)
ffffffffc0202ec0:	9782                	jalr	a5
ffffffffc0202ec2:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202ec4:	aebfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ec8:	b39d                	j	ffffffffc0202c2e <pmm_init+0x3d0>
ffffffffc0202eca:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ecc:	ae9fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202ed0:	000b3783          	ld	a5,0(s6)
ffffffffc0202ed4:	6522                	ld	a0,8(sp)
ffffffffc0202ed6:	4585                	li	a1,1
ffffffffc0202ed8:	739c                	ld	a5,32(a5)
ffffffffc0202eda:	9782                	jalr	a5
        intr_enable();
ffffffffc0202edc:	ad3fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ee0:	b33d                	j	ffffffffc0202c0e <pmm_init+0x3b0>
ffffffffc0202ee2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ee4:	ad1fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202ee8:	000b3783          	ld	a5,0(s6)
ffffffffc0202eec:	6522                	ld	a0,8(sp)
ffffffffc0202eee:	4585                	li	a1,1
ffffffffc0202ef0:	739c                	ld	a5,32(a5)
ffffffffc0202ef2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ef4:	abbfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ef8:	b1dd                	j	ffffffffc0202bde <pmm_init+0x380>
        intr_disable();
ffffffffc0202efa:	abbfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202efe:	000b3783          	ld	a5,0(s6)
ffffffffc0202f02:	4505                	li	a0,1
ffffffffc0202f04:	6f9c                	ld	a5,24(a5)
ffffffffc0202f06:	9782                	jalr	a5
ffffffffc0202f08:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202f0a:	aa5fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f0e:	b36d                	j	ffffffffc0202cb8 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202f10:	aa5fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202f14:	000b3783          	ld	a5,0(s6)
ffffffffc0202f18:	779c                	ld	a5,40(a5)
ffffffffc0202f1a:	9782                	jalr	a5
ffffffffc0202f1c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202f1e:	a91fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f22:	bdf9                	j	ffffffffc0202e00 <pmm_init+0x5a2>
ffffffffc0202f24:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202f26:	a8ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202f2a:	000b3783          	ld	a5,0(s6)
ffffffffc0202f2e:	6522                	ld	a0,8(sp)
ffffffffc0202f30:	4585                	li	a1,1
ffffffffc0202f32:	739c                	ld	a5,32(a5)
ffffffffc0202f34:	9782                	jalr	a5
        intr_enable();
ffffffffc0202f36:	a79fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f3a:	b55d                	j	ffffffffc0202de0 <pmm_init+0x582>
ffffffffc0202f3c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202f3e:	a77fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202f42:	000b3783          	ld	a5,0(s6)
ffffffffc0202f46:	6522                	ld	a0,8(sp)
ffffffffc0202f48:	4585                	li	a1,1
ffffffffc0202f4a:	739c                	ld	a5,32(a5)
ffffffffc0202f4c:	9782                	jalr	a5
        intr_enable();
ffffffffc0202f4e:	a61fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f52:	bdb9                	j	ffffffffc0202db0 <pmm_init+0x552>
        intr_disable();
ffffffffc0202f54:	a61fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202f58:	000b3783          	ld	a5,0(s6)
ffffffffc0202f5c:	4585                	li	a1,1
ffffffffc0202f5e:	8552                	mv	a0,s4
ffffffffc0202f60:	739c                	ld	a5,32(a5)
ffffffffc0202f62:	9782                	jalr	a5
        intr_enable();
ffffffffc0202f64:	a4bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f68:	bd29                	j	ffffffffc0202d82 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202f6a:	86a2                	mv	a3,s0
ffffffffc0202f6c:	00003617          	auipc	a2,0x3
ffffffffc0202f70:	2dc60613          	addi	a2,a2,732 # ffffffffc0206248 <commands+0x7b0>
ffffffffc0202f74:	25700593          	li	a1,599
ffffffffc0202f78:	00004517          	auipc	a0,0x4
ffffffffc0202f7c:	84050513          	addi	a0,a0,-1984 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0202f80:	d0efd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202f84:	00004697          	auipc	a3,0x4
ffffffffc0202f88:	ca468693          	addi	a3,a3,-860 # ffffffffc0206c28 <default_pmm_manager+0x588>
ffffffffc0202f8c:	00003617          	auipc	a2,0x3
ffffffffc0202f90:	36460613          	addi	a2,a2,868 # ffffffffc02062f0 <commands+0x858>
ffffffffc0202f94:	25800593          	li	a1,600
ffffffffc0202f98:	00004517          	auipc	a0,0x4
ffffffffc0202f9c:	82050513          	addi	a0,a0,-2016 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0202fa0:	ceefd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202fa4:	00004697          	auipc	a3,0x4
ffffffffc0202fa8:	c4468693          	addi	a3,a3,-956 # ffffffffc0206be8 <default_pmm_manager+0x548>
ffffffffc0202fac:	00003617          	auipc	a2,0x3
ffffffffc0202fb0:	34460613          	addi	a2,a2,836 # ffffffffc02062f0 <commands+0x858>
ffffffffc0202fb4:	25700593          	li	a1,599
ffffffffc0202fb8:	00004517          	auipc	a0,0x4
ffffffffc0202fbc:	80050513          	addi	a0,a0,-2048 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0202fc0:	ccefd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202fc4:	fc5fe0ef          	jal	ra,ffffffffc0201f88 <pa2page.part.0>
ffffffffc0202fc8:	fddfe0ef          	jal	ra,ffffffffc0201fa4 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202fcc:	00004697          	auipc	a3,0x4
ffffffffc0202fd0:	a1468693          	addi	a3,a3,-1516 # ffffffffc02069e0 <default_pmm_manager+0x340>
ffffffffc0202fd4:	00003617          	auipc	a2,0x3
ffffffffc0202fd8:	31c60613          	addi	a2,a2,796 # ffffffffc02062f0 <commands+0x858>
ffffffffc0202fdc:	22700593          	li	a1,551
ffffffffc0202fe0:	00003517          	auipc	a0,0x3
ffffffffc0202fe4:	7d850513          	addi	a0,a0,2008 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0202fe8:	ca6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202fec:	00004697          	auipc	a3,0x4
ffffffffc0202ff0:	93468693          	addi	a3,a3,-1740 # ffffffffc0206920 <default_pmm_manager+0x280>
ffffffffc0202ff4:	00003617          	auipc	a2,0x3
ffffffffc0202ff8:	2fc60613          	addi	a2,a2,764 # ffffffffc02062f0 <commands+0x858>
ffffffffc0202ffc:	21a00593          	li	a1,538
ffffffffc0203000:	00003517          	auipc	a0,0x3
ffffffffc0203004:	7b850513          	addi	a0,a0,1976 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203008:	c86fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc020300c:	00004697          	auipc	a3,0x4
ffffffffc0203010:	8d468693          	addi	a3,a3,-1836 # ffffffffc02068e0 <default_pmm_manager+0x240>
ffffffffc0203014:	00003617          	auipc	a2,0x3
ffffffffc0203018:	2dc60613          	addi	a2,a2,732 # ffffffffc02062f0 <commands+0x858>
ffffffffc020301c:	21900593          	li	a1,537
ffffffffc0203020:	00003517          	auipc	a0,0x3
ffffffffc0203024:	79850513          	addi	a0,a0,1944 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203028:	c66fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020302c:	00004697          	auipc	a3,0x4
ffffffffc0203030:	89468693          	addi	a3,a3,-1900 # ffffffffc02068c0 <default_pmm_manager+0x220>
ffffffffc0203034:	00003617          	auipc	a2,0x3
ffffffffc0203038:	2bc60613          	addi	a2,a2,700 # ffffffffc02062f0 <commands+0x858>
ffffffffc020303c:	21800593          	li	a1,536
ffffffffc0203040:	00003517          	auipc	a0,0x3
ffffffffc0203044:	77850513          	addi	a0,a0,1912 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203048:	c46fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc020304c:	00003617          	auipc	a2,0x3
ffffffffc0203050:	1fc60613          	addi	a2,a2,508 # ffffffffc0206248 <commands+0x7b0>
ffffffffc0203054:	07100593          	li	a1,113
ffffffffc0203058:	00003517          	auipc	a0,0x3
ffffffffc020305c:	21850513          	addi	a0,a0,536 # ffffffffc0206270 <commands+0x7d8>
ffffffffc0203060:	c2efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0203064:	00004697          	auipc	a3,0x4
ffffffffc0203068:	b0c68693          	addi	a3,a3,-1268 # ffffffffc0206b70 <default_pmm_manager+0x4d0>
ffffffffc020306c:	00003617          	auipc	a2,0x3
ffffffffc0203070:	28460613          	addi	a2,a2,644 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203074:	24000593          	li	a1,576
ffffffffc0203078:	00003517          	auipc	a0,0x3
ffffffffc020307c:	74050513          	addi	a0,a0,1856 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203080:	c0efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203084:	00004697          	auipc	a3,0x4
ffffffffc0203088:	aa468693          	addi	a3,a3,-1372 # ffffffffc0206b28 <default_pmm_manager+0x488>
ffffffffc020308c:	00003617          	auipc	a2,0x3
ffffffffc0203090:	26460613          	addi	a2,a2,612 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203094:	23e00593          	li	a1,574
ffffffffc0203098:	00003517          	auipc	a0,0x3
ffffffffc020309c:	72050513          	addi	a0,a0,1824 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02030a0:	beefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02030a4:	00004697          	auipc	a3,0x4
ffffffffc02030a8:	ab468693          	addi	a3,a3,-1356 # ffffffffc0206b58 <default_pmm_manager+0x4b8>
ffffffffc02030ac:	00003617          	auipc	a2,0x3
ffffffffc02030b0:	24460613          	addi	a2,a2,580 # ffffffffc02062f0 <commands+0x858>
ffffffffc02030b4:	23d00593          	li	a1,573
ffffffffc02030b8:	00003517          	auipc	a0,0x3
ffffffffc02030bc:	70050513          	addi	a0,a0,1792 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02030c0:	bcefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc02030c4:	00004697          	auipc	a3,0x4
ffffffffc02030c8:	b7c68693          	addi	a3,a3,-1156 # ffffffffc0206c40 <default_pmm_manager+0x5a0>
ffffffffc02030cc:	00003617          	auipc	a2,0x3
ffffffffc02030d0:	22460613          	addi	a2,a2,548 # ffffffffc02062f0 <commands+0x858>
ffffffffc02030d4:	25b00593          	li	a1,603
ffffffffc02030d8:	00003517          	auipc	a0,0x3
ffffffffc02030dc:	6e050513          	addi	a0,a0,1760 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02030e0:	baefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02030e4:	00004697          	auipc	a3,0x4
ffffffffc02030e8:	abc68693          	addi	a3,a3,-1348 # ffffffffc0206ba0 <default_pmm_manager+0x500>
ffffffffc02030ec:	00003617          	auipc	a2,0x3
ffffffffc02030f0:	20460613          	addi	a2,a2,516 # ffffffffc02062f0 <commands+0x858>
ffffffffc02030f4:	24800593          	li	a1,584
ffffffffc02030f8:	00003517          	auipc	a0,0x3
ffffffffc02030fc:	6c050513          	addi	a0,a0,1728 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203100:	b8efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203104:	00004697          	auipc	a3,0x4
ffffffffc0203108:	b9468693          	addi	a3,a3,-1132 # ffffffffc0206c98 <default_pmm_manager+0x5f8>
ffffffffc020310c:	00003617          	auipc	a2,0x3
ffffffffc0203110:	1e460613          	addi	a2,a2,484 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203114:	26000593          	li	a1,608
ffffffffc0203118:	00003517          	auipc	a0,0x3
ffffffffc020311c:	6a050513          	addi	a0,a0,1696 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203120:	b6efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203124:	00004697          	auipc	a3,0x4
ffffffffc0203128:	b3468693          	addi	a3,a3,-1228 # ffffffffc0206c58 <default_pmm_manager+0x5b8>
ffffffffc020312c:	00003617          	auipc	a2,0x3
ffffffffc0203130:	1c460613          	addi	a2,a2,452 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203134:	25f00593          	li	a1,607
ffffffffc0203138:	00003517          	auipc	a0,0x3
ffffffffc020313c:	68050513          	addi	a0,a0,1664 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203140:	b4efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203144:	00004697          	auipc	a3,0x4
ffffffffc0203148:	9e468693          	addi	a3,a3,-1564 # ffffffffc0206b28 <default_pmm_manager+0x488>
ffffffffc020314c:	00003617          	auipc	a2,0x3
ffffffffc0203150:	1a460613          	addi	a2,a2,420 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203154:	23a00593          	li	a1,570
ffffffffc0203158:	00003517          	auipc	a0,0x3
ffffffffc020315c:	66050513          	addi	a0,a0,1632 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203160:	b2efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203164:	00004697          	auipc	a3,0x4
ffffffffc0203168:	86468693          	addi	a3,a3,-1948 # ffffffffc02069c8 <default_pmm_manager+0x328>
ffffffffc020316c:	00003617          	auipc	a2,0x3
ffffffffc0203170:	18460613          	addi	a2,a2,388 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203174:	23900593          	li	a1,569
ffffffffc0203178:	00003517          	auipc	a0,0x3
ffffffffc020317c:	64050513          	addi	a0,a0,1600 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203180:	b0efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203184:	00004697          	auipc	a3,0x4
ffffffffc0203188:	9bc68693          	addi	a3,a3,-1604 # ffffffffc0206b40 <default_pmm_manager+0x4a0>
ffffffffc020318c:	00003617          	auipc	a2,0x3
ffffffffc0203190:	16460613          	addi	a2,a2,356 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203194:	23600593          	li	a1,566
ffffffffc0203198:	00003517          	auipc	a0,0x3
ffffffffc020319c:	62050513          	addi	a0,a0,1568 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02031a0:	aeefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02031a4:	00004697          	auipc	a3,0x4
ffffffffc02031a8:	80c68693          	addi	a3,a3,-2036 # ffffffffc02069b0 <default_pmm_manager+0x310>
ffffffffc02031ac:	00003617          	auipc	a2,0x3
ffffffffc02031b0:	14460613          	addi	a2,a2,324 # ffffffffc02062f0 <commands+0x858>
ffffffffc02031b4:	23500593          	li	a1,565
ffffffffc02031b8:	00003517          	auipc	a0,0x3
ffffffffc02031bc:	60050513          	addi	a0,a0,1536 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02031c0:	acefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02031c4:	00004697          	auipc	a3,0x4
ffffffffc02031c8:	88c68693          	addi	a3,a3,-1908 # ffffffffc0206a50 <default_pmm_manager+0x3b0>
ffffffffc02031cc:	00003617          	auipc	a2,0x3
ffffffffc02031d0:	12460613          	addi	a2,a2,292 # ffffffffc02062f0 <commands+0x858>
ffffffffc02031d4:	23400593          	li	a1,564
ffffffffc02031d8:	00003517          	auipc	a0,0x3
ffffffffc02031dc:	5e050513          	addi	a0,a0,1504 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02031e0:	aaefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02031e4:	00004697          	auipc	a3,0x4
ffffffffc02031e8:	94468693          	addi	a3,a3,-1724 # ffffffffc0206b28 <default_pmm_manager+0x488>
ffffffffc02031ec:	00003617          	auipc	a2,0x3
ffffffffc02031f0:	10460613          	addi	a2,a2,260 # ffffffffc02062f0 <commands+0x858>
ffffffffc02031f4:	23300593          	li	a1,563
ffffffffc02031f8:	00003517          	auipc	a0,0x3
ffffffffc02031fc:	5c050513          	addi	a0,a0,1472 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203200:	a8efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203204:	00004697          	auipc	a3,0x4
ffffffffc0203208:	90c68693          	addi	a3,a3,-1780 # ffffffffc0206b10 <default_pmm_manager+0x470>
ffffffffc020320c:	00003617          	auipc	a2,0x3
ffffffffc0203210:	0e460613          	addi	a2,a2,228 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203214:	23200593          	li	a1,562
ffffffffc0203218:	00003517          	auipc	a0,0x3
ffffffffc020321c:	5a050513          	addi	a0,a0,1440 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203220:	a6efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203224:	00004697          	auipc	a3,0x4
ffffffffc0203228:	8bc68693          	addi	a3,a3,-1860 # ffffffffc0206ae0 <default_pmm_manager+0x440>
ffffffffc020322c:	00003617          	auipc	a2,0x3
ffffffffc0203230:	0c460613          	addi	a2,a2,196 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203234:	23100593          	li	a1,561
ffffffffc0203238:	00003517          	auipc	a0,0x3
ffffffffc020323c:	58050513          	addi	a0,a0,1408 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203240:	a4efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203244:	00004697          	auipc	a3,0x4
ffffffffc0203248:	88468693          	addi	a3,a3,-1916 # ffffffffc0206ac8 <default_pmm_manager+0x428>
ffffffffc020324c:	00003617          	auipc	a2,0x3
ffffffffc0203250:	0a460613          	addi	a2,a2,164 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203254:	22f00593          	li	a1,559
ffffffffc0203258:	00003517          	auipc	a0,0x3
ffffffffc020325c:	56050513          	addi	a0,a0,1376 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203260:	a2efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203264:	00004697          	auipc	a3,0x4
ffffffffc0203268:	84468693          	addi	a3,a3,-1980 # ffffffffc0206aa8 <default_pmm_manager+0x408>
ffffffffc020326c:	00003617          	auipc	a2,0x3
ffffffffc0203270:	08460613          	addi	a2,a2,132 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203274:	22e00593          	li	a1,558
ffffffffc0203278:	00003517          	auipc	a0,0x3
ffffffffc020327c:	54050513          	addi	a0,a0,1344 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203280:	a0efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203284:	00004697          	auipc	a3,0x4
ffffffffc0203288:	81468693          	addi	a3,a3,-2028 # ffffffffc0206a98 <default_pmm_manager+0x3f8>
ffffffffc020328c:	00003617          	auipc	a2,0x3
ffffffffc0203290:	06460613          	addi	a2,a2,100 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203294:	22d00593          	li	a1,557
ffffffffc0203298:	00003517          	auipc	a0,0x3
ffffffffc020329c:	52050513          	addi	a0,a0,1312 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02032a0:	9eefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc02032a4:	00003697          	auipc	a3,0x3
ffffffffc02032a8:	7e468693          	addi	a3,a3,2020 # ffffffffc0206a88 <default_pmm_manager+0x3e8>
ffffffffc02032ac:	00003617          	auipc	a2,0x3
ffffffffc02032b0:	04460613          	addi	a2,a2,68 # ffffffffc02062f0 <commands+0x858>
ffffffffc02032b4:	22c00593          	li	a1,556
ffffffffc02032b8:	00003517          	auipc	a0,0x3
ffffffffc02032bc:	50050513          	addi	a0,a0,1280 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02032c0:	9cefd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc02032c4:	00003617          	auipc	a2,0x3
ffffffffc02032c8:	56460613          	addi	a2,a2,1380 # ffffffffc0206828 <default_pmm_manager+0x188>
ffffffffc02032cc:	06500593          	li	a1,101
ffffffffc02032d0:	00003517          	auipc	a0,0x3
ffffffffc02032d4:	4e850513          	addi	a0,a0,1256 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02032d8:	9b6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02032dc:	00004697          	auipc	a3,0x4
ffffffffc02032e0:	8c468693          	addi	a3,a3,-1852 # ffffffffc0206ba0 <default_pmm_manager+0x500>
ffffffffc02032e4:	00003617          	auipc	a2,0x3
ffffffffc02032e8:	00c60613          	addi	a2,a2,12 # ffffffffc02062f0 <commands+0x858>
ffffffffc02032ec:	27200593          	li	a1,626
ffffffffc02032f0:	00003517          	auipc	a0,0x3
ffffffffc02032f4:	4c850513          	addi	a0,a0,1224 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02032f8:	996fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02032fc:	00003697          	auipc	a3,0x3
ffffffffc0203300:	75468693          	addi	a3,a3,1876 # ffffffffc0206a50 <default_pmm_manager+0x3b0>
ffffffffc0203304:	00003617          	auipc	a2,0x3
ffffffffc0203308:	fec60613          	addi	a2,a2,-20 # ffffffffc02062f0 <commands+0x858>
ffffffffc020330c:	22b00593          	li	a1,555
ffffffffc0203310:	00003517          	auipc	a0,0x3
ffffffffc0203314:	4a850513          	addi	a0,a0,1192 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203318:	976fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020331c:	00003697          	auipc	a3,0x3
ffffffffc0203320:	6f468693          	addi	a3,a3,1780 # ffffffffc0206a10 <default_pmm_manager+0x370>
ffffffffc0203324:	00003617          	auipc	a2,0x3
ffffffffc0203328:	fcc60613          	addi	a2,a2,-52 # ffffffffc02062f0 <commands+0x858>
ffffffffc020332c:	22a00593          	li	a1,554
ffffffffc0203330:	00003517          	auipc	a0,0x3
ffffffffc0203334:	48850513          	addi	a0,a0,1160 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203338:	956fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020333c:	86d6                	mv	a3,s5
ffffffffc020333e:	00003617          	auipc	a2,0x3
ffffffffc0203342:	f0a60613          	addi	a2,a2,-246 # ffffffffc0206248 <commands+0x7b0>
ffffffffc0203346:	22600593          	li	a1,550
ffffffffc020334a:	00003517          	auipc	a0,0x3
ffffffffc020334e:	46e50513          	addi	a0,a0,1134 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203352:	93cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203356:	00003617          	auipc	a2,0x3
ffffffffc020335a:	ef260613          	addi	a2,a2,-270 # ffffffffc0206248 <commands+0x7b0>
ffffffffc020335e:	22500593          	li	a1,549
ffffffffc0203362:	00003517          	auipc	a0,0x3
ffffffffc0203366:	45650513          	addi	a0,a0,1110 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc020336a:	924fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020336e:	00003697          	auipc	a3,0x3
ffffffffc0203372:	65a68693          	addi	a3,a3,1626 # ffffffffc02069c8 <default_pmm_manager+0x328>
ffffffffc0203376:	00003617          	auipc	a2,0x3
ffffffffc020337a:	f7a60613          	addi	a2,a2,-134 # ffffffffc02062f0 <commands+0x858>
ffffffffc020337e:	22300593          	li	a1,547
ffffffffc0203382:	00003517          	auipc	a0,0x3
ffffffffc0203386:	43650513          	addi	a0,a0,1078 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc020338a:	904fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020338e:	00003697          	auipc	a3,0x3
ffffffffc0203392:	62268693          	addi	a3,a3,1570 # ffffffffc02069b0 <default_pmm_manager+0x310>
ffffffffc0203396:	00003617          	auipc	a2,0x3
ffffffffc020339a:	f5a60613          	addi	a2,a2,-166 # ffffffffc02062f0 <commands+0x858>
ffffffffc020339e:	22200593          	li	a1,546
ffffffffc02033a2:	00003517          	auipc	a0,0x3
ffffffffc02033a6:	41650513          	addi	a0,a0,1046 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02033aa:	8e4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02033ae:	00004697          	auipc	a3,0x4
ffffffffc02033b2:	9b268693          	addi	a3,a3,-1614 # ffffffffc0206d60 <default_pmm_manager+0x6c0>
ffffffffc02033b6:	00003617          	auipc	a2,0x3
ffffffffc02033ba:	f3a60613          	addi	a2,a2,-198 # ffffffffc02062f0 <commands+0x858>
ffffffffc02033be:	26900593          	li	a1,617
ffffffffc02033c2:	00003517          	auipc	a0,0x3
ffffffffc02033c6:	3f650513          	addi	a0,a0,1014 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02033ca:	8c4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02033ce:	00004697          	auipc	a3,0x4
ffffffffc02033d2:	95a68693          	addi	a3,a3,-1702 # ffffffffc0206d28 <default_pmm_manager+0x688>
ffffffffc02033d6:	00003617          	auipc	a2,0x3
ffffffffc02033da:	f1a60613          	addi	a2,a2,-230 # ffffffffc02062f0 <commands+0x858>
ffffffffc02033de:	26600593          	li	a1,614
ffffffffc02033e2:	00003517          	auipc	a0,0x3
ffffffffc02033e6:	3d650513          	addi	a0,a0,982 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02033ea:	8a4fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc02033ee:	00004697          	auipc	a3,0x4
ffffffffc02033f2:	90a68693          	addi	a3,a3,-1782 # ffffffffc0206cf8 <default_pmm_manager+0x658>
ffffffffc02033f6:	00003617          	auipc	a2,0x3
ffffffffc02033fa:	efa60613          	addi	a2,a2,-262 # ffffffffc02062f0 <commands+0x858>
ffffffffc02033fe:	26200593          	li	a1,610
ffffffffc0203402:	00003517          	auipc	a0,0x3
ffffffffc0203406:	3b650513          	addi	a0,a0,950 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc020340a:	884fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020340e:	00004697          	auipc	a3,0x4
ffffffffc0203412:	8a268693          	addi	a3,a3,-1886 # ffffffffc0206cb0 <default_pmm_manager+0x610>
ffffffffc0203416:	00003617          	auipc	a2,0x3
ffffffffc020341a:	eda60613          	addi	a2,a2,-294 # ffffffffc02062f0 <commands+0x858>
ffffffffc020341e:	26100593          	li	a1,609
ffffffffc0203422:	00003517          	auipc	a0,0x3
ffffffffc0203426:	39650513          	addi	a0,a0,918 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc020342a:	864fd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020342e:	00003617          	auipc	a2,0x3
ffffffffc0203432:	31a60613          	addi	a2,a2,794 # ffffffffc0206748 <default_pmm_manager+0xa8>
ffffffffc0203436:	0c900593          	li	a1,201
ffffffffc020343a:	00003517          	auipc	a0,0x3
ffffffffc020343e:	37e50513          	addi	a0,a0,894 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203442:	84cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203446:	00003617          	auipc	a2,0x3
ffffffffc020344a:	30260613          	addi	a2,a2,770 # ffffffffc0206748 <default_pmm_manager+0xa8>
ffffffffc020344e:	08100593          	li	a1,129
ffffffffc0203452:	00003517          	auipc	a0,0x3
ffffffffc0203456:	36650513          	addi	a0,a0,870 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc020345a:	834fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020345e:	00003697          	auipc	a3,0x3
ffffffffc0203462:	52268693          	addi	a3,a3,1314 # ffffffffc0206980 <default_pmm_manager+0x2e0>
ffffffffc0203466:	00003617          	auipc	a2,0x3
ffffffffc020346a:	e8a60613          	addi	a2,a2,-374 # ffffffffc02062f0 <commands+0x858>
ffffffffc020346e:	22100593          	li	a1,545
ffffffffc0203472:	00003517          	auipc	a0,0x3
ffffffffc0203476:	34650513          	addi	a0,a0,838 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc020347a:	814fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020347e:	00003697          	auipc	a3,0x3
ffffffffc0203482:	4d268693          	addi	a3,a3,1234 # ffffffffc0206950 <default_pmm_manager+0x2b0>
ffffffffc0203486:	00003617          	auipc	a2,0x3
ffffffffc020348a:	e6a60613          	addi	a2,a2,-406 # ffffffffc02062f0 <commands+0x858>
ffffffffc020348e:	21e00593          	li	a1,542
ffffffffc0203492:	00003517          	auipc	a0,0x3
ffffffffc0203496:	32650513          	addi	a0,a0,806 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc020349a:	ff5fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020349e <copy_range>:
{
ffffffffc020349e:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02034a0:	00d667b3          	or	a5,a2,a3
{
ffffffffc02034a4:	e03a                	sd	a4,0(sp)
ffffffffc02034a6:	fc86                	sd	ra,120(sp)
ffffffffc02034a8:	f8a2                	sd	s0,112(sp)
ffffffffc02034aa:	f4a6                	sd	s1,104(sp)
ffffffffc02034ac:	f0ca                	sd	s2,96(sp)
ffffffffc02034ae:	ecce                	sd	s3,88(sp)
ffffffffc02034b0:	e8d2                	sd	s4,80(sp)
ffffffffc02034b2:	e4d6                	sd	s5,72(sp)
ffffffffc02034b4:	e0da                	sd	s6,64(sp)
ffffffffc02034b6:	fc5e                	sd	s7,56(sp)
ffffffffc02034b8:	f862                	sd	s8,48(sp)
ffffffffc02034ba:	f466                	sd	s9,40(sp)
ffffffffc02034bc:	f06a                	sd	s10,32(sp)
ffffffffc02034be:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02034c0:	03479713          	slli	a4,a5,0x34
ffffffffc02034c4:	28071363          	bnez	a4,ffffffffc020374a <copy_range+0x2ac>
    assert(USER_ACCESS(start, end));
ffffffffc02034c8:	002007b7          	lui	a5,0x200
ffffffffc02034cc:	24f66f63          	bltu	a2,a5,ffffffffc020372a <copy_range+0x28c>
ffffffffc02034d0:	8936                	mv	s2,a3
ffffffffc02034d2:	24d67c63          	bgeu	a2,a3,ffffffffc020372a <copy_range+0x28c>
ffffffffc02034d6:	4785                	li	a5,1
ffffffffc02034d8:	6705                	lui	a4,0x1
ffffffffc02034da:	07fe                	slli	a5,a5,0x1f
ffffffffc02034dc:	00e60bb3          	add	s7,a2,a4
ffffffffc02034e0:	24d7e563          	bltu	a5,a3,ffffffffc020372a <copy_range+0x28c>
ffffffffc02034e4:	5b7d                	li	s6,-1
ffffffffc02034e6:	00cb5793          	srli	a5,s6,0xc
ffffffffc02034ea:	8a2a                	mv	s4,a0
ffffffffc02034ec:	84ae                	mv	s1,a1
ffffffffc02034ee:	79fd                	lui	s3,0xfffff
    if (PPN(pa) >= npage)
ffffffffc02034f0:	000a7c97          	auipc	s9,0xa7
ffffffffc02034f4:	1e0c8c93          	addi	s9,s9,480 # ffffffffc02aa6d0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02034f8:	000a7c17          	auipc	s8,0xa7
ffffffffc02034fc:	1e0c0c13          	addi	s8,s8,480 # ffffffffc02aa6d8 <pages>
    return KADDR(page2pa(page));
ffffffffc0203500:	e43e                	sd	a5,8(sp)
        page = pmm_manager->alloc_pages(n);
ffffffffc0203502:	000a7d17          	auipc	s10,0xa7
ffffffffc0203506:	1ded0d13          	addi	s10,s10,478 # ffffffffc02aa6e0 <pmm_manager>
ffffffffc020350a:	a031                	j	ffffffffc0203516 <copy_range+0x78>
    } while (start != 0 && start < end);
ffffffffc020350c:	6785                	lui	a5,0x1
ffffffffc020350e:	97de                	add	a5,a5,s7
ffffffffc0203510:	092bf963          	bgeu	s7,s2,ffffffffc02035a2 <copy_range+0x104>
ffffffffc0203514:	8bbe                	mv	s7,a5
ffffffffc0203516:	013b8b33          	add	s6,s7,s3
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020351a:	4601                	li	a2,0
ffffffffc020351c:	85da                	mv	a1,s6
ffffffffc020351e:	8526                	mv	a0,s1
ffffffffc0203520:	b59fe0ef          	jal	ra,ffffffffc0202078 <get_pte>
ffffffffc0203524:	8aaa                	mv	s5,a0
        if (ptep == NULL)
ffffffffc0203526:	d17d                	beqz	a0,ffffffffc020350c <copy_range+0x6e>
        if (*ptep & PTE_V) // 源页面有效
ffffffffc0203528:	6114                	ld	a3,0(a0)
ffffffffc020352a:	8a85                	andi	a3,a3,1
ffffffffc020352c:	d2e5                	beqz	a3,ffffffffc020350c <copy_range+0x6e>
            nptep = get_pte(to, start, 1);
ffffffffc020352e:	4605                	li	a2,1
ffffffffc0203530:	85da                	mv	a1,s6
ffffffffc0203532:	8552                	mv	a0,s4
ffffffffc0203534:	b45fe0ef          	jal	ra,ffffffffc0202078 <get_pte>
            if (nptep == NULL)
ffffffffc0203538:	14050763          	beqz	a0,ffffffffc0203686 <copy_range+0x1e8>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc020353c:	000ab683          	ld	a3,0(s5)
            if (share) {
ffffffffc0203540:	6782                	ld	a5,0(sp)
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203542:	0006841b          	sext.w	s0,a3
            if (share) {
ffffffffc0203546:	cfbd                	beqz	a5,ffffffffc02035c4 <copy_range+0x126>
    if (!(pte & PTE_V))
ffffffffc0203548:	0016f613          	andi	a2,a3,1
ffffffffc020354c:	1a060663          	beqz	a2,ffffffffc02036f8 <copy_range+0x25a>
    if (PPN(pa) >= npage)
ffffffffc0203550:	000cb603          	ld	a2,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203554:	068a                	slli	a3,a3,0x2
ffffffffc0203556:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0203558:	18c6f463          	bgeu	a3,a2,ffffffffc02036e0 <copy_range+0x242>
    return &pages[PPN(pa) - nbase];
ffffffffc020355c:	000c3583          	ld	a1,0(s8)
ffffffffc0203560:	fff807b7          	lui	a5,0xfff80
ffffffffc0203564:	96be                	add	a3,a3,a5
ffffffffc0203566:	069a                	slli	a3,a3,0x6
ffffffffc0203568:	00d58db3          	add	s11,a1,a3
                assert(page != NULL);
ffffffffc020356c:	140d8a63          	beqz	s11,ffffffffc02036c0 <copy_range+0x222>
                perm &= ~PTE_W;  // 移除写权限（保留R/X/U）
ffffffffc0203570:	886d                	andi	s0,s0,27
                page_insert(from, page, start, perm);
ffffffffc0203572:	86a2                	mv	a3,s0
ffffffffc0203574:	865a                	mv	a2,s6
ffffffffc0203576:	85ee                	mv	a1,s11
ffffffffc0203578:	8526                	mv	a0,s1
ffffffffc020357a:	9eeff0ef          	jal	ra,ffffffffc0202768 <page_insert>
                int ret = page_insert(to, page, start, perm);
ffffffffc020357e:	865a                	mv	a2,s6
ffffffffc0203580:	86a2                	mv	a3,s0
ffffffffc0203582:	85ee                	mv	a1,s11
ffffffffc0203584:	8552                	mv	a0,s4
ffffffffc0203586:	9e2ff0ef          	jal	ra,ffffffffc0202768 <page_insert>
                *ptep = (*ptep & ~PTE_W) | (perm & PTE_USER); // 保留核心权限
ffffffffc020358a:	000ab603          	ld	a2,0(s5)
ffffffffc020358e:	9a6d                	andi	a2,a2,-5
ffffffffc0203590:	8e41                	or	a2,a2,s0
ffffffffc0203592:	00cab023          	sd	a2,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203596:	120b0073          	sfence.vma	s6
    } while (start != 0 && start < end);
ffffffffc020359a:	6785                	lui	a5,0x1
ffffffffc020359c:	97de                	add	a5,a5,s7
ffffffffc020359e:	f72bebe3          	bltu	s7,s2,ffffffffc0203514 <copy_range+0x76>
    return 0;
ffffffffc02035a2:	4401                	li	s0,0
}
ffffffffc02035a4:	70e6                	ld	ra,120(sp)
ffffffffc02035a6:	8522                	mv	a0,s0
ffffffffc02035a8:	7446                	ld	s0,112(sp)
ffffffffc02035aa:	74a6                	ld	s1,104(sp)
ffffffffc02035ac:	7906                	ld	s2,96(sp)
ffffffffc02035ae:	69e6                	ld	s3,88(sp)
ffffffffc02035b0:	6a46                	ld	s4,80(sp)
ffffffffc02035b2:	6aa6                	ld	s5,72(sp)
ffffffffc02035b4:	6b06                	ld	s6,64(sp)
ffffffffc02035b6:	7be2                	ld	s7,56(sp)
ffffffffc02035b8:	7c42                	ld	s8,48(sp)
ffffffffc02035ba:	7ca2                	ld	s9,40(sp)
ffffffffc02035bc:	7d02                	ld	s10,32(sp)
ffffffffc02035be:	6de2                	ld	s11,24(sp)
ffffffffc02035c0:	6109                	addi	sp,sp,128
ffffffffc02035c2:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02035c4:	100026f3          	csrr	a3,sstatus
ffffffffc02035c8:	8a89                	andi	a3,a3,2
ffffffffc02035ca:	e2dd                	bnez	a3,ffffffffc0203670 <copy_range+0x1d2>
        page = pmm_manager->alloc_pages(n);
ffffffffc02035cc:	000d3683          	ld	a3,0(s10)
ffffffffc02035d0:	4505                	li	a0,1
ffffffffc02035d2:	6e94                	ld	a3,24(a3)
ffffffffc02035d4:	9682                	jalr	a3
ffffffffc02035d6:	8daa                	mv	s11,a0
                if (npage == NULL) {
ffffffffc02035d8:	0a0d8763          	beqz	s11,ffffffffc0203686 <copy_range+0x1e8>
                struct Page *page = pte2page(*ptep);
ffffffffc02035dc:	000ab683          	ld	a3,0(s5)
    if (!(pte & PTE_V))
ffffffffc02035e0:	0016f793          	andi	a5,a3,1
ffffffffc02035e4:	10078a63          	beqz	a5,ffffffffc02036f8 <copy_range+0x25a>
    if (PPN(pa) >= npage)
ffffffffc02035e8:	000cb303          	ld	t1,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02035ec:	068a                	slli	a3,a3,0x2
ffffffffc02035ee:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc02035f0:	0e66f863          	bgeu	a3,t1,ffffffffc02036e0 <copy_range+0x242>
    return &pages[PPN(pa) - nbase];
ffffffffc02035f4:	fff807b7          	lui	a5,0xfff80
ffffffffc02035f8:	000c3603          	ld	a2,0(s8)
ffffffffc02035fc:	96be                	add	a3,a3,a5
ffffffffc02035fe:	069a                	slli	a3,a3,0x6
ffffffffc0203600:	00d607b3          	add	a5,a2,a3
                assert(page != NULL);
ffffffffc0203604:	cfd1                	beqz	a5,ffffffffc02036a0 <copy_range+0x202>
    return KADDR(page2pa(page));
ffffffffc0203606:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0203608:	8699                	srai	a3,a3,0x6
ffffffffc020360a:	000805b7          	lui	a1,0x80
ffffffffc020360e:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0203610:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0203612:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203614:	0e67ff63          	bgeu	a5,t1,ffffffffc0203712 <copy_range+0x274>
ffffffffc0203618:	000a7717          	auipc	a4,0xa7
ffffffffc020361c:	0d070713          	addi	a4,a4,208 # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc0203620:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc0203622:	40cd87b3          	sub	a5,s11,a2
    return KADDR(page2pa(page));
ffffffffc0203626:	6722                	ld	a4,8(sp)
    return page - pages + nbase;
ffffffffc0203628:	8799                	srai	a5,a5,0x6
ffffffffc020362a:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc020362c:	00e7f633          	and	a2,a5,a4
ffffffffc0203630:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203634:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203636:	0c667d63          	bgeu	a2,t1,ffffffffc0203710 <copy_range+0x272>
                memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc020363a:	6605                	lui	a2,0x1
ffffffffc020363c:	953e                	add	a0,a0,a5
ffffffffc020363e:	1d6020ef          	jal	ra,ffffffffc0205814 <memcpy>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203642:	01f47693          	andi	a3,s0,31
                int ret = page_insert(to, npage, start, perm);
ffffffffc0203646:	0046e693          	ori	a3,a3,4
ffffffffc020364a:	865a                	mv	a2,s6
ffffffffc020364c:	85ee                	mv	a1,s11
ffffffffc020364e:	8552                	mv	a0,s4
ffffffffc0203650:	918ff0ef          	jal	ra,ffffffffc0202768 <page_insert>
ffffffffc0203654:	842a                	mv	s0,a0
                if (ret != 0) {
ffffffffc0203656:	ea050be3          	beqz	a0,ffffffffc020350c <copy_range+0x6e>
ffffffffc020365a:	100027f3          	csrr	a5,sstatus
ffffffffc020365e:	8b89                	andi	a5,a5,2
ffffffffc0203660:	e78d                	bnez	a5,ffffffffc020368a <copy_range+0x1ec>
        pmm_manager->free_pages(base, n);
ffffffffc0203662:	000d3783          	ld	a5,0(s10)
ffffffffc0203666:	4585                	li	a1,1
ffffffffc0203668:	856e                	mv	a0,s11
ffffffffc020366a:	739c                	ld	a5,32(a5)
ffffffffc020366c:	9782                	jalr	a5
    if (flag)
ffffffffc020366e:	bf1d                	j	ffffffffc02035a4 <copy_range+0x106>
        intr_disable();
ffffffffc0203670:	b44fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203674:	000d3683          	ld	a3,0(s10)
ffffffffc0203678:	4505                	li	a0,1
ffffffffc020367a:	6e94                	ld	a3,24(a3)
ffffffffc020367c:	9682                	jalr	a3
ffffffffc020367e:	8daa                	mv	s11,a0
        intr_enable();
ffffffffc0203680:	b2efd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203684:	bf91                	j	ffffffffc02035d8 <copy_range+0x13a>
                return -E_NO_MEM;
ffffffffc0203686:	5471                	li	s0,-4
ffffffffc0203688:	bf31                	j	ffffffffc02035a4 <copy_range+0x106>
        intr_disable();
ffffffffc020368a:	b2afd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020368e:	000d3783          	ld	a5,0(s10)
ffffffffc0203692:	4585                	li	a1,1
ffffffffc0203694:	856e                	mv	a0,s11
ffffffffc0203696:	739c                	ld	a5,32(a5)
ffffffffc0203698:	9782                	jalr	a5
        intr_enable();
ffffffffc020369a:	b14fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020369e:	b719                	j	ffffffffc02035a4 <copy_range+0x106>
                assert(page != NULL);
ffffffffc02036a0:	00003697          	auipc	a3,0x3
ffffffffc02036a4:	70868693          	addi	a3,a3,1800 # ffffffffc0206da8 <default_pmm_manager+0x708>
ffffffffc02036a8:	00003617          	auipc	a2,0x3
ffffffffc02036ac:	c4860613          	addi	a2,a2,-952 # ffffffffc02062f0 <commands+0x858>
ffffffffc02036b0:	1a700593          	li	a1,423
ffffffffc02036b4:	00003517          	auipc	a0,0x3
ffffffffc02036b8:	10450513          	addi	a0,a0,260 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02036bc:	dd3fc0ef          	jal	ra,ffffffffc020048e <__panic>
                assert(page != NULL);
ffffffffc02036c0:	00003697          	auipc	a3,0x3
ffffffffc02036c4:	6e868693          	addi	a3,a3,1768 # ffffffffc0206da8 <default_pmm_manager+0x708>
ffffffffc02036c8:	00003617          	auipc	a2,0x3
ffffffffc02036cc:	c2860613          	addi	a2,a2,-984 # ffffffffc02062f0 <commands+0x858>
ffffffffc02036d0:	19600593          	li	a1,406
ffffffffc02036d4:	00003517          	auipc	a0,0x3
ffffffffc02036d8:	0e450513          	addi	a0,a0,228 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc02036dc:	db3fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02036e0:	00003617          	auipc	a2,0x3
ffffffffc02036e4:	09060613          	addi	a2,a2,144 # ffffffffc0206770 <default_pmm_manager+0xd0>
ffffffffc02036e8:	06900593          	li	a1,105
ffffffffc02036ec:	00003517          	auipc	a0,0x3
ffffffffc02036f0:	b8450513          	addi	a0,a0,-1148 # ffffffffc0206270 <commands+0x7d8>
ffffffffc02036f4:	d9bfc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02036f8:	00003617          	auipc	a2,0x3
ffffffffc02036fc:	09860613          	addi	a2,a2,152 # ffffffffc0206790 <default_pmm_manager+0xf0>
ffffffffc0203700:	07f00593          	li	a1,127
ffffffffc0203704:	00003517          	auipc	a0,0x3
ffffffffc0203708:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0206270 <commands+0x7d8>
ffffffffc020370c:	d83fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0203710:	86be                	mv	a3,a5
ffffffffc0203712:	00003617          	auipc	a2,0x3
ffffffffc0203716:	b3660613          	addi	a2,a2,-1226 # ffffffffc0206248 <commands+0x7b0>
ffffffffc020371a:	07100593          	li	a1,113
ffffffffc020371e:	00003517          	auipc	a0,0x3
ffffffffc0203722:	b5250513          	addi	a0,a0,-1198 # ffffffffc0206270 <commands+0x7d8>
ffffffffc0203726:	d69fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020372a:	00003697          	auipc	a3,0x3
ffffffffc020372e:	0ce68693          	addi	a3,a3,206 # ffffffffc02067f8 <default_pmm_manager+0x158>
ffffffffc0203732:	00003617          	auipc	a2,0x3
ffffffffc0203736:	bbe60613          	addi	a2,a2,-1090 # ffffffffc02062f0 <commands+0x858>
ffffffffc020373a:	17c00593          	li	a1,380
ffffffffc020373e:	00003517          	auipc	a0,0x3
ffffffffc0203742:	07a50513          	addi	a0,a0,122 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203746:	d49fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020374a:	00003697          	auipc	a3,0x3
ffffffffc020374e:	07e68693          	addi	a3,a3,126 # ffffffffc02067c8 <default_pmm_manager+0x128>
ffffffffc0203752:	00003617          	auipc	a2,0x3
ffffffffc0203756:	b9e60613          	addi	a2,a2,-1122 # ffffffffc02062f0 <commands+0x858>
ffffffffc020375a:	17b00593          	li	a1,379
ffffffffc020375e:	00003517          	auipc	a0,0x3
ffffffffc0203762:	05a50513          	addi	a0,a0,90 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc0203766:	d29fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020376a <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020376a:	12058073          	sfence.vma	a1
}
ffffffffc020376e:	8082                	ret

ffffffffc0203770 <pgdir_alloc_page>:
{
ffffffffc0203770:	7179                	addi	sp,sp,-48
ffffffffc0203772:	ec26                	sd	s1,24(sp)
ffffffffc0203774:	e84a                	sd	s2,16(sp)
ffffffffc0203776:	e052                	sd	s4,0(sp)
ffffffffc0203778:	f406                	sd	ra,40(sp)
ffffffffc020377a:	f022                	sd	s0,32(sp)
ffffffffc020377c:	e44e                	sd	s3,8(sp)
ffffffffc020377e:	8a2a                	mv	s4,a0
ffffffffc0203780:	84ae                	mv	s1,a1
ffffffffc0203782:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203784:	100027f3          	csrr	a5,sstatus
ffffffffc0203788:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc020378a:	000a7997          	auipc	s3,0xa7
ffffffffc020378e:	f5698993          	addi	s3,s3,-170 # ffffffffc02aa6e0 <pmm_manager>
ffffffffc0203792:	ef8d                	bnez	a5,ffffffffc02037cc <pgdir_alloc_page+0x5c>
ffffffffc0203794:	0009b783          	ld	a5,0(s3)
ffffffffc0203798:	4505                	li	a0,1
ffffffffc020379a:	6f9c                	ld	a5,24(a5)
ffffffffc020379c:	9782                	jalr	a5
ffffffffc020379e:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02037a0:	cc09                	beqz	s0,ffffffffc02037ba <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02037a2:	86ca                	mv	a3,s2
ffffffffc02037a4:	8626                	mv	a2,s1
ffffffffc02037a6:	85a2                	mv	a1,s0
ffffffffc02037a8:	8552                	mv	a0,s4
ffffffffc02037aa:	fbffe0ef          	jal	ra,ffffffffc0202768 <page_insert>
ffffffffc02037ae:	e915                	bnez	a0,ffffffffc02037e2 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc02037b0:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc02037b2:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc02037b4:	4785                	li	a5,1
ffffffffc02037b6:	04f71e63          	bne	a4,a5,ffffffffc0203812 <pgdir_alloc_page+0xa2>
}
ffffffffc02037ba:	70a2                	ld	ra,40(sp)
ffffffffc02037bc:	8522                	mv	a0,s0
ffffffffc02037be:	7402                	ld	s0,32(sp)
ffffffffc02037c0:	64e2                	ld	s1,24(sp)
ffffffffc02037c2:	6942                	ld	s2,16(sp)
ffffffffc02037c4:	69a2                	ld	s3,8(sp)
ffffffffc02037c6:	6a02                	ld	s4,0(sp)
ffffffffc02037c8:	6145                	addi	sp,sp,48
ffffffffc02037ca:	8082                	ret
        intr_disable();
ffffffffc02037cc:	9e8fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02037d0:	0009b783          	ld	a5,0(s3)
ffffffffc02037d4:	4505                	li	a0,1
ffffffffc02037d6:	6f9c                	ld	a5,24(a5)
ffffffffc02037d8:	9782                	jalr	a5
ffffffffc02037da:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02037dc:	9d2fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02037e0:	b7c1                	j	ffffffffc02037a0 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02037e2:	100027f3          	csrr	a5,sstatus
ffffffffc02037e6:	8b89                	andi	a5,a5,2
ffffffffc02037e8:	eb89                	bnez	a5,ffffffffc02037fa <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc02037ea:	0009b783          	ld	a5,0(s3)
ffffffffc02037ee:	8522                	mv	a0,s0
ffffffffc02037f0:	4585                	li	a1,1
ffffffffc02037f2:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc02037f4:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc02037f6:	9782                	jalr	a5
    if (flag)
ffffffffc02037f8:	b7c9                	j	ffffffffc02037ba <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc02037fa:	9bafd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02037fe:	0009b783          	ld	a5,0(s3)
ffffffffc0203802:	8522                	mv	a0,s0
ffffffffc0203804:	4585                	li	a1,1
ffffffffc0203806:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203808:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020380a:	9782                	jalr	a5
        intr_enable();
ffffffffc020380c:	9a2fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203810:	b76d                	j	ffffffffc02037ba <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203812:	00003697          	auipc	a3,0x3
ffffffffc0203816:	5a668693          	addi	a3,a3,1446 # ffffffffc0206db8 <default_pmm_manager+0x718>
ffffffffc020381a:	00003617          	auipc	a2,0x3
ffffffffc020381e:	ad660613          	addi	a2,a2,-1322 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203822:	1ff00593          	li	a1,511
ffffffffc0203826:	00003517          	auipc	a0,0x3
ffffffffc020382a:	f9250513          	addi	a0,a0,-110 # ffffffffc02067b8 <default_pmm_manager+0x118>
ffffffffc020382e:	c61fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203832 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203832:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203834:	00003697          	auipc	a3,0x3
ffffffffc0203838:	59c68693          	addi	a3,a3,1436 # ffffffffc0206dd0 <default_pmm_manager+0x730>
ffffffffc020383c:	00003617          	auipc	a2,0x3
ffffffffc0203840:	ab460613          	addi	a2,a2,-1356 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203844:	07400593          	li	a1,116
ffffffffc0203848:	00003517          	auipc	a0,0x3
ffffffffc020384c:	5a850513          	addi	a0,a0,1448 # ffffffffc0206df0 <default_pmm_manager+0x750>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203850:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203852:	c3dfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203856 <mm_create>:
{
ffffffffc0203856:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203858:	04000513          	li	a0,64
{
ffffffffc020385c:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020385e:	d84fe0ef          	jal	ra,ffffffffc0201de2 <kmalloc>
    if (mm != NULL)
ffffffffc0203862:	cd19                	beqz	a0,ffffffffc0203880 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc0203864:	e508                	sd	a0,8(a0)
ffffffffc0203866:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203868:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020386c:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203870:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203874:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc0203878:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc020387c:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203880:	60a2                	ld	ra,8(sp)
ffffffffc0203882:	0141                	addi	sp,sp,16
ffffffffc0203884:	8082                	ret

ffffffffc0203886 <find_vma>:
{
ffffffffc0203886:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0203888:	c505                	beqz	a0,ffffffffc02038b0 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc020388a:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020388c:	c501                	beqz	a0,ffffffffc0203894 <find_vma+0xe>
ffffffffc020388e:	651c                	ld	a5,8(a0)
ffffffffc0203890:	02f5f263          	bgeu	a1,a5,ffffffffc02038b4 <find_vma+0x2e>
    return listelm->next;
ffffffffc0203894:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0203896:	00f68d63          	beq	a3,a5,ffffffffc02038b0 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc020389a:	fe87b703          	ld	a4,-24(a5) # fffffffffff7ffe8 <end+0x3fcd58dc>
ffffffffc020389e:	00e5e663          	bltu	a1,a4,ffffffffc02038aa <find_vma+0x24>
ffffffffc02038a2:	ff07b703          	ld	a4,-16(a5)
ffffffffc02038a6:	00e5ec63          	bltu	a1,a4,ffffffffc02038be <find_vma+0x38>
ffffffffc02038aa:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02038ac:	fef697e3          	bne	a3,a5,ffffffffc020389a <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02038b0:	4501                	li	a0,0
}
ffffffffc02038b2:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02038b4:	691c                	ld	a5,16(a0)
ffffffffc02038b6:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0203894 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02038ba:	ea88                	sd	a0,16(a3)
ffffffffc02038bc:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02038be:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc02038c2:	ea88                	sd	a0,16(a3)
ffffffffc02038c4:	8082                	ret

ffffffffc02038c6 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02038c6:	6590                	ld	a2,8(a1)
ffffffffc02038c8:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_exit_out_size+0x74ef0>
{
ffffffffc02038cc:	1141                	addi	sp,sp,-16
ffffffffc02038ce:	e406                	sd	ra,8(sp)
ffffffffc02038d0:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02038d2:	01066763          	bltu	a2,a6,ffffffffc02038e0 <insert_vma_struct+0x1a>
ffffffffc02038d6:	a085                	j	ffffffffc0203936 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc02038d8:	fe87b703          	ld	a4,-24(a5)
ffffffffc02038dc:	04e66863          	bltu	a2,a4,ffffffffc020392c <insert_vma_struct+0x66>
ffffffffc02038e0:	86be                	mv	a3,a5
ffffffffc02038e2:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc02038e4:	fef51ae3          	bne	a0,a5,ffffffffc02038d8 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc02038e8:	02a68463          	beq	a3,a0,ffffffffc0203910 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02038ec:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02038f0:	fe86b883          	ld	a7,-24(a3)
ffffffffc02038f4:	08e8f163          	bgeu	a7,a4,ffffffffc0203976 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02038f8:	04e66f63          	bltu	a2,a4,ffffffffc0203956 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc02038fc:	00f50a63          	beq	a0,a5,ffffffffc0203910 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203900:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203904:	05076963          	bltu	a4,a6,ffffffffc0203956 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203908:	ff07b603          	ld	a2,-16(a5)
ffffffffc020390c:	02c77363          	bgeu	a4,a2,ffffffffc0203932 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203910:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203912:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203914:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203918:	e390                	sd	a2,0(a5)
ffffffffc020391a:	e690                	sd	a2,8(a3)
}
ffffffffc020391c:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020391e:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203920:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203922:	0017079b          	addiw	a5,a4,1
ffffffffc0203926:	d11c                	sw	a5,32(a0)
}
ffffffffc0203928:	0141                	addi	sp,sp,16
ffffffffc020392a:	8082                	ret
    if (le_prev != list)
ffffffffc020392c:	fca690e3          	bne	a3,a0,ffffffffc02038ec <insert_vma_struct+0x26>
ffffffffc0203930:	bfd1                	j	ffffffffc0203904 <insert_vma_struct+0x3e>
ffffffffc0203932:	f01ff0ef          	jal	ra,ffffffffc0203832 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203936:	00003697          	auipc	a3,0x3
ffffffffc020393a:	4ca68693          	addi	a3,a3,1226 # ffffffffc0206e00 <default_pmm_manager+0x760>
ffffffffc020393e:	00003617          	auipc	a2,0x3
ffffffffc0203942:	9b260613          	addi	a2,a2,-1614 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203946:	07a00593          	li	a1,122
ffffffffc020394a:	00003517          	auipc	a0,0x3
ffffffffc020394e:	4a650513          	addi	a0,a0,1190 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203952:	b3dfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203956:	00003697          	auipc	a3,0x3
ffffffffc020395a:	4ea68693          	addi	a3,a3,1258 # ffffffffc0206e40 <default_pmm_manager+0x7a0>
ffffffffc020395e:	00003617          	auipc	a2,0x3
ffffffffc0203962:	99260613          	addi	a2,a2,-1646 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203966:	07300593          	li	a1,115
ffffffffc020396a:	00003517          	auipc	a0,0x3
ffffffffc020396e:	48650513          	addi	a0,a0,1158 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203972:	b1dfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203976:	00003697          	auipc	a3,0x3
ffffffffc020397a:	4aa68693          	addi	a3,a3,1194 # ffffffffc0206e20 <default_pmm_manager+0x780>
ffffffffc020397e:	00003617          	auipc	a2,0x3
ffffffffc0203982:	97260613          	addi	a2,a2,-1678 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203986:	07200593          	li	a1,114
ffffffffc020398a:	00003517          	auipc	a0,0x3
ffffffffc020398e:	46650513          	addi	a0,a0,1126 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203992:	afdfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203996 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0203996:	591c                	lw	a5,48(a0)
{
ffffffffc0203998:	1141                	addi	sp,sp,-16
ffffffffc020399a:	e406                	sd	ra,8(sp)
ffffffffc020399c:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc020399e:	e78d                	bnez	a5,ffffffffc02039c8 <mm_destroy+0x32>
ffffffffc02039a0:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02039a2:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02039a4:	00a40c63          	beq	s0,a0,ffffffffc02039bc <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02039a8:	6118                	ld	a4,0(a0)
ffffffffc02039aa:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02039ac:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02039ae:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02039b0:	e398                	sd	a4,0(a5)
ffffffffc02039b2:	ce0fe0ef          	jal	ra,ffffffffc0201e92 <kfree>
    return listelm->next;
ffffffffc02039b6:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02039b8:	fea418e3          	bne	s0,a0,ffffffffc02039a8 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc02039bc:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02039be:	6402                	ld	s0,0(sp)
ffffffffc02039c0:	60a2                	ld	ra,8(sp)
ffffffffc02039c2:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02039c4:	ccefe06f          	j	ffffffffc0201e92 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02039c8:	00003697          	auipc	a3,0x3
ffffffffc02039cc:	49868693          	addi	a3,a3,1176 # ffffffffc0206e60 <default_pmm_manager+0x7c0>
ffffffffc02039d0:	00003617          	auipc	a2,0x3
ffffffffc02039d4:	92060613          	addi	a2,a2,-1760 # ffffffffc02062f0 <commands+0x858>
ffffffffc02039d8:	09e00593          	li	a1,158
ffffffffc02039dc:	00003517          	auipc	a0,0x3
ffffffffc02039e0:	41450513          	addi	a0,a0,1044 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc02039e4:	aabfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039e8 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc02039e8:	7139                	addi	sp,sp,-64
ffffffffc02039ea:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02039ec:	6405                	lui	s0,0x1
ffffffffc02039ee:	147d                	addi	s0,s0,-1
ffffffffc02039f0:	77fd                	lui	a5,0xfffff
ffffffffc02039f2:	9622                	add	a2,a2,s0
ffffffffc02039f4:	962e                	add	a2,a2,a1
{
ffffffffc02039f6:	f426                	sd	s1,40(sp)
ffffffffc02039f8:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02039fa:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc02039fe:	f04a                	sd	s2,32(sp)
ffffffffc0203a00:	ec4e                	sd	s3,24(sp)
ffffffffc0203a02:	e852                	sd	s4,16(sp)
ffffffffc0203a04:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203a06:	002005b7          	lui	a1,0x200
ffffffffc0203a0a:	00f67433          	and	s0,a2,a5
ffffffffc0203a0e:	06b4e363          	bltu	s1,a1,ffffffffc0203a74 <mm_map+0x8c>
ffffffffc0203a12:	0684f163          	bgeu	s1,s0,ffffffffc0203a74 <mm_map+0x8c>
ffffffffc0203a16:	4785                	li	a5,1
ffffffffc0203a18:	07fe                	slli	a5,a5,0x1f
ffffffffc0203a1a:	0487ed63          	bltu	a5,s0,ffffffffc0203a74 <mm_map+0x8c>
ffffffffc0203a1e:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203a20:	cd21                	beqz	a0,ffffffffc0203a78 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203a22:	85a6                	mv	a1,s1
ffffffffc0203a24:	8ab6                	mv	s5,a3
ffffffffc0203a26:	8a3a                	mv	s4,a4
ffffffffc0203a28:	e5fff0ef          	jal	ra,ffffffffc0203886 <find_vma>
ffffffffc0203a2c:	c501                	beqz	a0,ffffffffc0203a34 <mm_map+0x4c>
ffffffffc0203a2e:	651c                	ld	a5,8(a0)
ffffffffc0203a30:	0487e263          	bltu	a5,s0,ffffffffc0203a74 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a34:	03000513          	li	a0,48
ffffffffc0203a38:	baafe0ef          	jal	ra,ffffffffc0201de2 <kmalloc>
ffffffffc0203a3c:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203a3e:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203a40:	02090163          	beqz	s2,ffffffffc0203a62 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203a44:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0203a46:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0203a4a:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0203a4e:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0203a52:	85ca                	mv	a1,s2
ffffffffc0203a54:	e73ff0ef          	jal	ra,ffffffffc02038c6 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0203a58:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc0203a5a:	000a0463          	beqz	s4,ffffffffc0203a62 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0203a5e:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc0203a62:	70e2                	ld	ra,56(sp)
ffffffffc0203a64:	7442                	ld	s0,48(sp)
ffffffffc0203a66:	74a2                	ld	s1,40(sp)
ffffffffc0203a68:	7902                	ld	s2,32(sp)
ffffffffc0203a6a:	69e2                	ld	s3,24(sp)
ffffffffc0203a6c:	6a42                	ld	s4,16(sp)
ffffffffc0203a6e:	6aa2                	ld	s5,8(sp)
ffffffffc0203a70:	6121                	addi	sp,sp,64
ffffffffc0203a72:	8082                	ret
        return -E_INVAL;
ffffffffc0203a74:	5575                	li	a0,-3
ffffffffc0203a76:	b7f5                	j	ffffffffc0203a62 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc0203a78:	00003697          	auipc	a3,0x3
ffffffffc0203a7c:	40068693          	addi	a3,a3,1024 # ffffffffc0206e78 <default_pmm_manager+0x7d8>
ffffffffc0203a80:	00003617          	auipc	a2,0x3
ffffffffc0203a84:	87060613          	addi	a2,a2,-1936 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203a88:	0b300593          	li	a1,179
ffffffffc0203a8c:	00003517          	auipc	a0,0x3
ffffffffc0203a90:	36450513          	addi	a0,a0,868 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203a94:	9fbfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a98 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203a98:	7139                	addi	sp,sp,-64
ffffffffc0203a9a:	fc06                	sd	ra,56(sp)
ffffffffc0203a9c:	f822                	sd	s0,48(sp)
ffffffffc0203a9e:	f426                	sd	s1,40(sp)
ffffffffc0203aa0:	f04a                	sd	s2,32(sp)
ffffffffc0203aa2:	ec4e                	sd	s3,24(sp)
ffffffffc0203aa4:	e852                	sd	s4,16(sp)
ffffffffc0203aa6:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203aa8:	c52d                	beqz	a0,ffffffffc0203b12 <dup_mmap+0x7a>
ffffffffc0203aaa:	892a                	mv	s2,a0
ffffffffc0203aac:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203aae:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203ab0:	e595                	bnez	a1,ffffffffc0203adc <dup_mmap+0x44>
ffffffffc0203ab2:	a085                	j	ffffffffc0203b12 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203ab4:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203ab6:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ee8>
        vma->vm_end = vm_end;
ffffffffc0203aba:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203abe:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203ac2:	e05ff0ef          	jal	ra,ffffffffc02038c6 <insert_vma_struct>

        bool share = 1; // 使用COW机制
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203ac6:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc0203aca:	fe843603          	ld	a2,-24(s0)
ffffffffc0203ace:	6c8c                	ld	a1,24(s1)
ffffffffc0203ad0:	01893503          	ld	a0,24(s2)
ffffffffc0203ad4:	4705                	li	a4,1
ffffffffc0203ad6:	9c9ff0ef          	jal	ra,ffffffffc020349e <copy_range>
ffffffffc0203ada:	e105                	bnez	a0,ffffffffc0203afa <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203adc:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203ade:	02848863          	beq	s1,s0,ffffffffc0203b0e <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203ae2:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203ae6:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203aea:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203aee:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203af2:	af0fe0ef          	jal	ra,ffffffffc0201de2 <kmalloc>
ffffffffc0203af6:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203af8:	fd55                	bnez	a0,ffffffffc0203ab4 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203afa:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203afc:	70e2                	ld	ra,56(sp)
ffffffffc0203afe:	7442                	ld	s0,48(sp)
ffffffffc0203b00:	74a2                	ld	s1,40(sp)
ffffffffc0203b02:	7902                	ld	s2,32(sp)
ffffffffc0203b04:	69e2                	ld	s3,24(sp)
ffffffffc0203b06:	6a42                	ld	s4,16(sp)
ffffffffc0203b08:	6aa2                	ld	s5,8(sp)
ffffffffc0203b0a:	6121                	addi	sp,sp,64
ffffffffc0203b0c:	8082                	ret
    return 0;
ffffffffc0203b0e:	4501                	li	a0,0
ffffffffc0203b10:	b7f5                	j	ffffffffc0203afc <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203b12:	00003697          	auipc	a3,0x3
ffffffffc0203b16:	37668693          	addi	a3,a3,886 # ffffffffc0206e88 <default_pmm_manager+0x7e8>
ffffffffc0203b1a:	00002617          	auipc	a2,0x2
ffffffffc0203b1e:	7d660613          	addi	a2,a2,2006 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203b22:	0cf00593          	li	a1,207
ffffffffc0203b26:	00003517          	auipc	a0,0x3
ffffffffc0203b2a:	2ca50513          	addi	a0,a0,714 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203b2e:	961fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203b32 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203b32:	1101                	addi	sp,sp,-32
ffffffffc0203b34:	ec06                	sd	ra,24(sp)
ffffffffc0203b36:	e822                	sd	s0,16(sp)
ffffffffc0203b38:	e426                	sd	s1,8(sp)
ffffffffc0203b3a:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203b3c:	c531                	beqz	a0,ffffffffc0203b88 <exit_mmap+0x56>
ffffffffc0203b3e:	591c                	lw	a5,48(a0)
ffffffffc0203b40:	84aa                	mv	s1,a0
ffffffffc0203b42:	e3b9                	bnez	a5,ffffffffc0203b88 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203b44:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203b46:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203b4a:	02850663          	beq	a0,s0,ffffffffc0203b76 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203b4e:	ff043603          	ld	a2,-16(s0)
ffffffffc0203b52:	fe843583          	ld	a1,-24(s0)
ffffffffc0203b56:	854a                	mv	a0,s2
ffffffffc0203b58:	f9cfe0ef          	jal	ra,ffffffffc02022f4 <unmap_range>
ffffffffc0203b5c:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203b5e:	fe8498e3          	bne	s1,s0,ffffffffc0203b4e <exit_mmap+0x1c>
ffffffffc0203b62:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203b64:	00848c63          	beq	s1,s0,ffffffffc0203b7c <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203b68:	ff043603          	ld	a2,-16(s0)
ffffffffc0203b6c:	fe843583          	ld	a1,-24(s0)
ffffffffc0203b70:	854a                	mv	a0,s2
ffffffffc0203b72:	8c9fe0ef          	jal	ra,ffffffffc020243a <exit_range>
ffffffffc0203b76:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203b78:	fe8498e3          	bne	s1,s0,ffffffffc0203b68 <exit_mmap+0x36>
    }
}
ffffffffc0203b7c:	60e2                	ld	ra,24(sp)
ffffffffc0203b7e:	6442                	ld	s0,16(sp)
ffffffffc0203b80:	64a2                	ld	s1,8(sp)
ffffffffc0203b82:	6902                	ld	s2,0(sp)
ffffffffc0203b84:	6105                	addi	sp,sp,32
ffffffffc0203b86:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203b88:	00003697          	auipc	a3,0x3
ffffffffc0203b8c:	32068693          	addi	a3,a3,800 # ffffffffc0206ea8 <default_pmm_manager+0x808>
ffffffffc0203b90:	00002617          	auipc	a2,0x2
ffffffffc0203b94:	76060613          	addi	a2,a2,1888 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203b98:	0e800593          	li	a1,232
ffffffffc0203b9c:	00003517          	auipc	a0,0x3
ffffffffc0203ba0:	25450513          	addi	a0,a0,596 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203ba4:	8ebfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203ba8 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203ba8:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203baa:	04000513          	li	a0,64
{
ffffffffc0203bae:	fc06                	sd	ra,56(sp)
ffffffffc0203bb0:	f822                	sd	s0,48(sp)
ffffffffc0203bb2:	f426                	sd	s1,40(sp)
ffffffffc0203bb4:	f04a                	sd	s2,32(sp)
ffffffffc0203bb6:	ec4e                	sd	s3,24(sp)
ffffffffc0203bb8:	e852                	sd	s4,16(sp)
ffffffffc0203bba:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203bbc:	a26fe0ef          	jal	ra,ffffffffc0201de2 <kmalloc>
    if (mm != NULL)
ffffffffc0203bc0:	2e050663          	beqz	a0,ffffffffc0203eac <vmm_init+0x304>
ffffffffc0203bc4:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203bc6:	e508                	sd	a0,8(a0)
ffffffffc0203bc8:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203bca:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203bce:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203bd2:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203bd6:	02053423          	sd	zero,40(a0)
ffffffffc0203bda:	02052823          	sw	zero,48(a0)
ffffffffc0203bde:	02053c23          	sd	zero,56(a0)
ffffffffc0203be2:	03200413          	li	s0,50
ffffffffc0203be6:	a811                	j	ffffffffc0203bfa <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203be8:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203bea:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203bec:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203bf0:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203bf2:	8526                	mv	a0,s1
ffffffffc0203bf4:	cd3ff0ef          	jal	ra,ffffffffc02038c6 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203bf8:	c80d                	beqz	s0,ffffffffc0203c2a <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203bfa:	03000513          	li	a0,48
ffffffffc0203bfe:	9e4fe0ef          	jal	ra,ffffffffc0201de2 <kmalloc>
ffffffffc0203c02:	85aa                	mv	a1,a0
ffffffffc0203c04:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203c08:	f165                	bnez	a0,ffffffffc0203be8 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203c0a:	00003697          	auipc	a3,0x3
ffffffffc0203c0e:	43668693          	addi	a3,a3,1078 # ffffffffc0207040 <default_pmm_manager+0x9a0>
ffffffffc0203c12:	00002617          	auipc	a2,0x2
ffffffffc0203c16:	6de60613          	addi	a2,a2,1758 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203c1a:	12c00593          	li	a1,300
ffffffffc0203c1e:	00003517          	auipc	a0,0x3
ffffffffc0203c22:	1d250513          	addi	a0,a0,466 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203c26:	869fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203c2a:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203c2e:	1f900913          	li	s2,505
ffffffffc0203c32:	a819                	j	ffffffffc0203c48 <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203c34:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203c36:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203c38:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203c3c:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203c3e:	8526                	mv	a0,s1
ffffffffc0203c40:	c87ff0ef          	jal	ra,ffffffffc02038c6 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203c44:	03240a63          	beq	s0,s2,ffffffffc0203c78 <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203c48:	03000513          	li	a0,48
ffffffffc0203c4c:	996fe0ef          	jal	ra,ffffffffc0201de2 <kmalloc>
ffffffffc0203c50:	85aa                	mv	a1,a0
ffffffffc0203c52:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203c56:	fd79                	bnez	a0,ffffffffc0203c34 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203c58:	00003697          	auipc	a3,0x3
ffffffffc0203c5c:	3e868693          	addi	a3,a3,1000 # ffffffffc0207040 <default_pmm_manager+0x9a0>
ffffffffc0203c60:	00002617          	auipc	a2,0x2
ffffffffc0203c64:	69060613          	addi	a2,a2,1680 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203c68:	13300593          	li	a1,307
ffffffffc0203c6c:	00003517          	auipc	a0,0x3
ffffffffc0203c70:	18450513          	addi	a0,a0,388 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203c74:	81bfc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203c78:	649c                	ld	a5,8(s1)
ffffffffc0203c7a:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203c7c:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203c80:	16f48663          	beq	s1,a5,ffffffffc0203dec <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203c84:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd548dc>
ffffffffc0203c88:	ffe70693          	addi	a3,a4,-2
ffffffffc0203c8c:	10d61063          	bne	a2,a3,ffffffffc0203d8c <vmm_init+0x1e4>
ffffffffc0203c90:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203c94:	0ed71c63          	bne	a4,a3,ffffffffc0203d8c <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203c98:	0715                	addi	a4,a4,5
ffffffffc0203c9a:	679c                	ld	a5,8(a5)
ffffffffc0203c9c:	feb712e3          	bne	a4,a1,ffffffffc0203c80 <vmm_init+0xd8>
ffffffffc0203ca0:	4a1d                	li	s4,7
ffffffffc0203ca2:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203ca4:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203ca8:	85a2                	mv	a1,s0
ffffffffc0203caa:	8526                	mv	a0,s1
ffffffffc0203cac:	bdbff0ef          	jal	ra,ffffffffc0203886 <find_vma>
ffffffffc0203cb0:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203cb2:	16050d63          	beqz	a0,ffffffffc0203e2c <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203cb6:	00140593          	addi	a1,s0,1
ffffffffc0203cba:	8526                	mv	a0,s1
ffffffffc0203cbc:	bcbff0ef          	jal	ra,ffffffffc0203886 <find_vma>
ffffffffc0203cc0:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203cc2:	14050563          	beqz	a0,ffffffffc0203e0c <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203cc6:	85d2                	mv	a1,s4
ffffffffc0203cc8:	8526                	mv	a0,s1
ffffffffc0203cca:	bbdff0ef          	jal	ra,ffffffffc0203886 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203cce:	16051f63          	bnez	a0,ffffffffc0203e4c <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203cd2:	00340593          	addi	a1,s0,3
ffffffffc0203cd6:	8526                	mv	a0,s1
ffffffffc0203cd8:	bafff0ef          	jal	ra,ffffffffc0203886 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203cdc:	1a051863          	bnez	a0,ffffffffc0203e8c <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203ce0:	00440593          	addi	a1,s0,4
ffffffffc0203ce4:	8526                	mv	a0,s1
ffffffffc0203ce6:	ba1ff0ef          	jal	ra,ffffffffc0203886 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203cea:	18051163          	bnez	a0,ffffffffc0203e6c <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203cee:	00893783          	ld	a5,8(s2)
ffffffffc0203cf2:	0a879d63          	bne	a5,s0,ffffffffc0203dac <vmm_init+0x204>
ffffffffc0203cf6:	01093783          	ld	a5,16(s2)
ffffffffc0203cfa:	0b479963          	bne	a5,s4,ffffffffc0203dac <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203cfe:	0089b783          	ld	a5,8(s3)
ffffffffc0203d02:	0c879563          	bne	a5,s0,ffffffffc0203dcc <vmm_init+0x224>
ffffffffc0203d06:	0109b783          	ld	a5,16(s3)
ffffffffc0203d0a:	0d479163          	bne	a5,s4,ffffffffc0203dcc <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203d0e:	0415                	addi	s0,s0,5
ffffffffc0203d10:	0a15                	addi	s4,s4,5
ffffffffc0203d12:	f9541be3          	bne	s0,s5,ffffffffc0203ca8 <vmm_init+0x100>
ffffffffc0203d16:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203d18:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203d1a:	85a2                	mv	a1,s0
ffffffffc0203d1c:	8526                	mv	a0,s1
ffffffffc0203d1e:	b69ff0ef          	jal	ra,ffffffffc0203886 <find_vma>
ffffffffc0203d22:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203d26:	c90d                	beqz	a0,ffffffffc0203d58 <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203d28:	6914                	ld	a3,16(a0)
ffffffffc0203d2a:	6510                	ld	a2,8(a0)
ffffffffc0203d2c:	00003517          	auipc	a0,0x3
ffffffffc0203d30:	29c50513          	addi	a0,a0,668 # ffffffffc0206fc8 <default_pmm_manager+0x928>
ffffffffc0203d34:	c60fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203d38:	00003697          	auipc	a3,0x3
ffffffffc0203d3c:	2b868693          	addi	a3,a3,696 # ffffffffc0206ff0 <default_pmm_manager+0x950>
ffffffffc0203d40:	00002617          	auipc	a2,0x2
ffffffffc0203d44:	5b060613          	addi	a2,a2,1456 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203d48:	15900593          	li	a1,345
ffffffffc0203d4c:	00003517          	auipc	a0,0x3
ffffffffc0203d50:	0a450513          	addi	a0,a0,164 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203d54:	f3afc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203d58:	147d                	addi	s0,s0,-1
ffffffffc0203d5a:	fd2410e3          	bne	s0,s2,ffffffffc0203d1a <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203d5e:	8526                	mv	a0,s1
ffffffffc0203d60:	c37ff0ef          	jal	ra,ffffffffc0203996 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203d64:	00003517          	auipc	a0,0x3
ffffffffc0203d68:	2a450513          	addi	a0,a0,676 # ffffffffc0207008 <default_pmm_manager+0x968>
ffffffffc0203d6c:	c28fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203d70:	7442                	ld	s0,48(sp)
ffffffffc0203d72:	70e2                	ld	ra,56(sp)
ffffffffc0203d74:	74a2                	ld	s1,40(sp)
ffffffffc0203d76:	7902                	ld	s2,32(sp)
ffffffffc0203d78:	69e2                	ld	s3,24(sp)
ffffffffc0203d7a:	6a42                	ld	s4,16(sp)
ffffffffc0203d7c:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203d7e:	00003517          	auipc	a0,0x3
ffffffffc0203d82:	2aa50513          	addi	a0,a0,682 # ffffffffc0207028 <default_pmm_manager+0x988>
}
ffffffffc0203d86:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203d88:	c0cfc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203d8c:	00003697          	auipc	a3,0x3
ffffffffc0203d90:	15468693          	addi	a3,a3,340 # ffffffffc0206ee0 <default_pmm_manager+0x840>
ffffffffc0203d94:	00002617          	auipc	a2,0x2
ffffffffc0203d98:	55c60613          	addi	a2,a2,1372 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203d9c:	13d00593          	li	a1,317
ffffffffc0203da0:	00003517          	auipc	a0,0x3
ffffffffc0203da4:	05050513          	addi	a0,a0,80 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203da8:	ee6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203dac:	00003697          	auipc	a3,0x3
ffffffffc0203db0:	1bc68693          	addi	a3,a3,444 # ffffffffc0206f68 <default_pmm_manager+0x8c8>
ffffffffc0203db4:	00002617          	auipc	a2,0x2
ffffffffc0203db8:	53c60613          	addi	a2,a2,1340 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203dbc:	14e00593          	li	a1,334
ffffffffc0203dc0:	00003517          	auipc	a0,0x3
ffffffffc0203dc4:	03050513          	addi	a0,a0,48 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203dc8:	ec6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203dcc:	00003697          	auipc	a3,0x3
ffffffffc0203dd0:	1cc68693          	addi	a3,a3,460 # ffffffffc0206f98 <default_pmm_manager+0x8f8>
ffffffffc0203dd4:	00002617          	auipc	a2,0x2
ffffffffc0203dd8:	51c60613          	addi	a2,a2,1308 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203ddc:	14f00593          	li	a1,335
ffffffffc0203de0:	00003517          	auipc	a0,0x3
ffffffffc0203de4:	01050513          	addi	a0,a0,16 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203de8:	ea6fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203dec:	00003697          	auipc	a3,0x3
ffffffffc0203df0:	0dc68693          	addi	a3,a3,220 # ffffffffc0206ec8 <default_pmm_manager+0x828>
ffffffffc0203df4:	00002617          	auipc	a2,0x2
ffffffffc0203df8:	4fc60613          	addi	a2,a2,1276 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203dfc:	13b00593          	li	a1,315
ffffffffc0203e00:	00003517          	auipc	a0,0x3
ffffffffc0203e04:	ff050513          	addi	a0,a0,-16 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203e08:	e86fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203e0c:	00003697          	auipc	a3,0x3
ffffffffc0203e10:	11c68693          	addi	a3,a3,284 # ffffffffc0206f28 <default_pmm_manager+0x888>
ffffffffc0203e14:	00002617          	auipc	a2,0x2
ffffffffc0203e18:	4dc60613          	addi	a2,a2,1244 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203e1c:	14600593          	li	a1,326
ffffffffc0203e20:	00003517          	auipc	a0,0x3
ffffffffc0203e24:	fd050513          	addi	a0,a0,-48 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203e28:	e66fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203e2c:	00003697          	auipc	a3,0x3
ffffffffc0203e30:	0ec68693          	addi	a3,a3,236 # ffffffffc0206f18 <default_pmm_manager+0x878>
ffffffffc0203e34:	00002617          	auipc	a2,0x2
ffffffffc0203e38:	4bc60613          	addi	a2,a2,1212 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203e3c:	14400593          	li	a1,324
ffffffffc0203e40:	00003517          	auipc	a0,0x3
ffffffffc0203e44:	fb050513          	addi	a0,a0,-80 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203e48:	e46fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203e4c:	00003697          	auipc	a3,0x3
ffffffffc0203e50:	0ec68693          	addi	a3,a3,236 # ffffffffc0206f38 <default_pmm_manager+0x898>
ffffffffc0203e54:	00002617          	auipc	a2,0x2
ffffffffc0203e58:	49c60613          	addi	a2,a2,1180 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203e5c:	14800593          	li	a1,328
ffffffffc0203e60:	00003517          	auipc	a0,0x3
ffffffffc0203e64:	f9050513          	addi	a0,a0,-112 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203e68:	e26fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203e6c:	00003697          	auipc	a3,0x3
ffffffffc0203e70:	0ec68693          	addi	a3,a3,236 # ffffffffc0206f58 <default_pmm_manager+0x8b8>
ffffffffc0203e74:	00002617          	auipc	a2,0x2
ffffffffc0203e78:	47c60613          	addi	a2,a2,1148 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203e7c:	14c00593          	li	a1,332
ffffffffc0203e80:	00003517          	auipc	a0,0x3
ffffffffc0203e84:	f7050513          	addi	a0,a0,-144 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203e88:	e06fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203e8c:	00003697          	auipc	a3,0x3
ffffffffc0203e90:	0bc68693          	addi	a3,a3,188 # ffffffffc0206f48 <default_pmm_manager+0x8a8>
ffffffffc0203e94:	00002617          	auipc	a2,0x2
ffffffffc0203e98:	45c60613          	addi	a2,a2,1116 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203e9c:	14a00593          	li	a1,330
ffffffffc0203ea0:	00003517          	auipc	a0,0x3
ffffffffc0203ea4:	f5050513          	addi	a0,a0,-176 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203ea8:	de6fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203eac:	00003697          	auipc	a3,0x3
ffffffffc0203eb0:	fcc68693          	addi	a3,a3,-52 # ffffffffc0206e78 <default_pmm_manager+0x7d8>
ffffffffc0203eb4:	00002617          	auipc	a2,0x2
ffffffffc0203eb8:	43c60613          	addi	a2,a2,1084 # ffffffffc02062f0 <commands+0x858>
ffffffffc0203ebc:	12400593          	li	a1,292
ffffffffc0203ec0:	00003517          	auipc	a0,0x3
ffffffffc0203ec4:	f3050513          	addi	a0,a0,-208 # ffffffffc0206df0 <default_pmm_manager+0x750>
ffffffffc0203ec8:	dc6fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203ecc <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203ecc:	7179                	addi	sp,sp,-48
ffffffffc0203ece:	f022                	sd	s0,32(sp)
ffffffffc0203ed0:	f406                	sd	ra,40(sp)
ffffffffc0203ed2:	ec26                	sd	s1,24(sp)
ffffffffc0203ed4:	e84a                	sd	s2,16(sp)
ffffffffc0203ed6:	e44e                	sd	s3,8(sp)
ffffffffc0203ed8:	e052                	sd	s4,0(sp)
ffffffffc0203eda:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203edc:	c135                	beqz	a0,ffffffffc0203f40 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203ede:	002007b7          	lui	a5,0x200
ffffffffc0203ee2:	04f5e663          	bltu	a1,a5,ffffffffc0203f2e <user_mem_check+0x62>
ffffffffc0203ee6:	00c584b3          	add	s1,a1,a2
ffffffffc0203eea:	0495f263          	bgeu	a1,s1,ffffffffc0203f2e <user_mem_check+0x62>
ffffffffc0203eee:	4785                	li	a5,1
ffffffffc0203ef0:	07fe                	slli	a5,a5,0x1f
ffffffffc0203ef2:	0297ee63          	bltu	a5,s1,ffffffffc0203f2e <user_mem_check+0x62>
ffffffffc0203ef6:	892a                	mv	s2,a0
ffffffffc0203ef8:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203efa:	6a05                	lui	s4,0x1
ffffffffc0203efc:	a821                	j	ffffffffc0203f14 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203efe:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f02:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203f04:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f06:	c685                	beqz	a3,ffffffffc0203f2e <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203f08:	c399                	beqz	a5,ffffffffc0203f0e <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f0a:	02e46263          	bltu	s0,a4,ffffffffc0203f2e <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203f0e:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203f10:	04947663          	bgeu	s0,s1,ffffffffc0203f5c <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203f14:	85a2                	mv	a1,s0
ffffffffc0203f16:	854a                	mv	a0,s2
ffffffffc0203f18:	96fff0ef          	jal	ra,ffffffffc0203886 <find_vma>
ffffffffc0203f1c:	c909                	beqz	a0,ffffffffc0203f2e <user_mem_check+0x62>
ffffffffc0203f1e:	6518                	ld	a4,8(a0)
ffffffffc0203f20:	00e46763          	bltu	s0,a4,ffffffffc0203f2e <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f24:	4d1c                	lw	a5,24(a0)
ffffffffc0203f26:	fc099ce3          	bnez	s3,ffffffffc0203efe <user_mem_check+0x32>
ffffffffc0203f2a:	8b85                	andi	a5,a5,1
ffffffffc0203f2c:	f3ed                	bnez	a5,ffffffffc0203f0e <user_mem_check+0x42>
            return 0;
ffffffffc0203f2e:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203f30:	70a2                	ld	ra,40(sp)
ffffffffc0203f32:	7402                	ld	s0,32(sp)
ffffffffc0203f34:	64e2                	ld	s1,24(sp)
ffffffffc0203f36:	6942                	ld	s2,16(sp)
ffffffffc0203f38:	69a2                	ld	s3,8(sp)
ffffffffc0203f3a:	6a02                	ld	s4,0(sp)
ffffffffc0203f3c:	6145                	addi	sp,sp,48
ffffffffc0203f3e:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203f40:	c02007b7          	lui	a5,0xc0200
ffffffffc0203f44:	4501                	li	a0,0
ffffffffc0203f46:	fef5e5e3          	bltu	a1,a5,ffffffffc0203f30 <user_mem_check+0x64>
ffffffffc0203f4a:	962e                	add	a2,a2,a1
ffffffffc0203f4c:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203f30 <user_mem_check+0x64>
ffffffffc0203f50:	c8000537          	lui	a0,0xc8000
ffffffffc0203f54:	0505                	addi	a0,a0,1
ffffffffc0203f56:	00a63533          	sltu	a0,a2,a0
ffffffffc0203f5a:	bfd9                	j	ffffffffc0203f30 <user_mem_check+0x64>
        return 1;
ffffffffc0203f5c:	4505                	li	a0,1
ffffffffc0203f5e:	bfc9                	j	ffffffffc0203f30 <user_mem_check+0x64>

ffffffffc0203f60 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203f60:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203f62:	9402                	jalr	s0

	jal do_exit
ffffffffc0203f64:	5d2000ef          	jal	ra,ffffffffc0204536 <do_exit>

ffffffffc0203f68 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203f68:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203f6a:	10800513          	li	a0,264
{
ffffffffc0203f6e:	e022                	sd	s0,0(sp)
ffffffffc0203f70:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203f72:	e71fd0ef          	jal	ra,ffffffffc0201de2 <kmalloc>
ffffffffc0203f76:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203f78:	cd21                	beqz	a0,ffffffffc0203fd0 <alloc_proc+0x68>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
         proc->state = 0;//初始值PROC_UNINIT
ffffffffc0203f7a:	57fd                	li	a5,-1
ffffffffc0203f7c:	1782                	slli	a5,a5,0x20
ffffffffc0203f7e:	e11c                	sd	a5,0(a0)
         proc->runs = 0;
         proc->kstack = 0;
         proc->need_resched = 0; //不用schedule调度其他进程
         proc->parent = NULL;
         proc->mm = NULL;
         memset(&proc->context, 0, sizeof(struct context));
ffffffffc0203f80:	07000613          	li	a2,112
ffffffffc0203f84:	4581                	li	a1,0
         proc->runs = 0;
ffffffffc0203f86:	00052423          	sw	zero,8(a0) # ffffffffc8000008 <end+0x7d558fc>
         proc->kstack = 0;
ffffffffc0203f8a:	00053823          	sd	zero,16(a0)
         proc->need_resched = 0; //不用schedule调度其他进程
ffffffffc0203f8e:	00053c23          	sd	zero,24(a0)
         proc->parent = NULL;
ffffffffc0203f92:	02053023          	sd	zero,32(a0)
         proc->mm = NULL;
ffffffffc0203f96:	02053423          	sd	zero,40(a0)
         memset(&proc->context, 0, sizeof(struct context));
ffffffffc0203f9a:	03050513          	addi	a0,a0,48
ffffffffc0203f9e:	065010ef          	jal	ra,ffffffffc0205802 <memset>
         proc->tf = NULL;
         proc->pgdir = boot_pgdir_pa;
ffffffffc0203fa2:	000a6797          	auipc	a5,0xa6
ffffffffc0203fa6:	71e7b783          	ld	a5,1822(a5) # ffffffffc02aa6c0 <boot_pgdir_pa>
         proc->tf = NULL;
ffffffffc0203faa:	0a043023          	sd	zero,160(s0)
         proc->pgdir = boot_pgdir_pa;
ffffffffc0203fae:	f45c                	sd	a5,168(s0)
         //cprintf("boot_pgdir_pa: %lx\n", boot_pgdir_pa);
         proc->flags = 0;
ffffffffc0203fb0:	0a042823          	sw	zero,176(s0)
         memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203fb4:	4641                	li	a2,16
ffffffffc0203fb6:	4581                	li	a1,0
ffffffffc0203fb8:	0b440513          	addi	a0,s0,180
ffffffffc0203fbc:	047010ef          	jal	ra,ffffffffc0205802 <memset>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
         proc->wait_state = 0;
ffffffffc0203fc0:	0e042623          	sw	zero,236(s0)
            proc->cptr = NULL;
ffffffffc0203fc4:	0e043823          	sd	zero,240(s0)
            proc->yptr = NULL;
ffffffffc0203fc8:	0e043c23          	sd	zero,248(s0)
            proc->optr = NULL;
ffffffffc0203fcc:	10043023          	sd	zero,256(s0)
    }
    return proc;
}
ffffffffc0203fd0:	60a2                	ld	ra,8(sp)
ffffffffc0203fd2:	8522                	mv	a0,s0
ffffffffc0203fd4:	6402                	ld	s0,0(sp)
ffffffffc0203fd6:	0141                	addi	sp,sp,16
ffffffffc0203fd8:	8082                	ret

ffffffffc0203fda <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203fda:	000a6797          	auipc	a5,0xa6
ffffffffc0203fde:	7167b783          	ld	a5,1814(a5) # ffffffffc02aa6f0 <current>
ffffffffc0203fe2:	73c8                	ld	a0,160(a5)
ffffffffc0203fe4:	872fd06f          	j	ffffffffc0201056 <forkrets>

ffffffffc0203fe8 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)// 进入kernel_execve，然后内联汇编，因为SYS_exec映射到sys_exec，然后sys_exec里return的是do_execve
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203fe8:	000a6797          	auipc	a5,0xa6
ffffffffc0203fec:	7087b783          	ld	a5,1800(a5) # ffffffffc02aa6f0 <current>
ffffffffc0203ff0:	43cc                	lw	a1,4(a5)
{
ffffffffc0203ff2:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203ff4:	00003617          	auipc	a2,0x3
ffffffffc0203ff8:	05c60613          	addi	a2,a2,92 # ffffffffc0207050 <default_pmm_manager+0x9b0>
ffffffffc0203ffc:	00003517          	auipc	a0,0x3
ffffffffc0204000:	06450513          	addi	a0,a0,100 # ffffffffc0207060 <default_pmm_manager+0x9c0>
{
ffffffffc0204004:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204006:	98efc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020400a:	3fe07797          	auipc	a5,0x3fe07
ffffffffc020400e:	95678793          	addi	a5,a5,-1706 # a960 <_binary_obj___user_forktest_out_size>
ffffffffc0204012:	e43e                	sd	a5,8(sp)
ffffffffc0204014:	00003517          	auipc	a0,0x3
ffffffffc0204018:	03c50513          	addi	a0,a0,60 # ffffffffc0207050 <default_pmm_manager+0x9b0>
ffffffffc020401c:	00045797          	auipc	a5,0x45
ffffffffc0204020:	6d478793          	addi	a5,a5,1748 # ffffffffc02496f0 <_binary_obj___user_forktest_out_start>
ffffffffc0204024:	f03e                	sd	a5,32(sp)
ffffffffc0204026:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0204028:	e802                	sd	zero,16(sp)
ffffffffc020402a:	736010ef          	jal	ra,ffffffffc0205760 <strlen>
ffffffffc020402e:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204030:	4511                	li	a0,4
ffffffffc0204032:	55a2                	lw	a1,40(sp)
ffffffffc0204034:	4662                	lw	a2,24(sp)
ffffffffc0204036:	5682                	lw	a3,32(sp)
ffffffffc0204038:	4722                	lw	a4,8(sp)
ffffffffc020403a:	48a9                	li	a7,10
ffffffffc020403c:	9002                	ebreak
ffffffffc020403e:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204040:	65c2                	ld	a1,16(sp)
ffffffffc0204042:	00003517          	auipc	a0,0x3
ffffffffc0204046:	04650513          	addi	a0,a0,70 # ffffffffc0207088 <default_pmm_manager+0x9e8>
ffffffffc020404a:	94afc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc020404e:	00003617          	auipc	a2,0x3
ffffffffc0204052:	04a60613          	addi	a2,a2,74 # ffffffffc0207098 <default_pmm_manager+0x9f8>
ffffffffc0204056:	3ad00593          	li	a1,941
ffffffffc020405a:	00003517          	auipc	a0,0x3
ffffffffc020405e:	05e50513          	addi	a0,a0,94 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0204062:	c2cfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204066 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204066:	6d14                	ld	a3,24(a0)
{
ffffffffc0204068:	1141                	addi	sp,sp,-16
ffffffffc020406a:	e406                	sd	ra,8(sp)
ffffffffc020406c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204070:	02f6ee63          	bltu	a3,a5,ffffffffc02040ac <put_pgdir+0x46>
ffffffffc0204074:	000a6517          	auipc	a0,0xa6
ffffffffc0204078:	67453503          	ld	a0,1652(a0) # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc020407c:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc020407e:	82b1                	srli	a3,a3,0xc
ffffffffc0204080:	000a6797          	auipc	a5,0xa6
ffffffffc0204084:	6507b783          	ld	a5,1616(a5) # ffffffffc02aa6d0 <npage>
ffffffffc0204088:	02f6fe63          	bgeu	a3,a5,ffffffffc02040c4 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc020408c:	00004517          	auipc	a0,0x4
ffffffffc0204090:	8c453503          	ld	a0,-1852(a0) # ffffffffc0207950 <nbase>
}
ffffffffc0204094:	60a2                	ld	ra,8(sp)
ffffffffc0204096:	8e89                	sub	a3,a3,a0
ffffffffc0204098:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc020409a:	000a6517          	auipc	a0,0xa6
ffffffffc020409e:	63e53503          	ld	a0,1598(a0) # ffffffffc02aa6d8 <pages>
ffffffffc02040a2:	4585                	li	a1,1
ffffffffc02040a4:	9536                	add	a0,a0,a3
}
ffffffffc02040a6:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc02040a8:	f57fd06f          	j	ffffffffc0201ffe <free_pages>
    return pa2page(PADDR(kva));
ffffffffc02040ac:	00002617          	auipc	a2,0x2
ffffffffc02040b0:	69c60613          	addi	a2,a2,1692 # ffffffffc0206748 <default_pmm_manager+0xa8>
ffffffffc02040b4:	07700593          	li	a1,119
ffffffffc02040b8:	00002517          	auipc	a0,0x2
ffffffffc02040bc:	1b850513          	addi	a0,a0,440 # ffffffffc0206270 <commands+0x7d8>
ffffffffc02040c0:	bcefc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02040c4:	00002617          	auipc	a2,0x2
ffffffffc02040c8:	6ac60613          	addi	a2,a2,1708 # ffffffffc0206770 <default_pmm_manager+0xd0>
ffffffffc02040cc:	06900593          	li	a1,105
ffffffffc02040d0:	00002517          	auipc	a0,0x2
ffffffffc02040d4:	1a050513          	addi	a0,a0,416 # ffffffffc0206270 <commands+0x7d8>
ffffffffc02040d8:	bb6fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02040dc <proc_run>:
{
ffffffffc02040dc:	7179                	addi	sp,sp,-48
ffffffffc02040de:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc02040e0:	000a6497          	auipc	s1,0xa6
ffffffffc02040e4:	61048493          	addi	s1,s1,1552 # ffffffffc02aa6f0 <current>
ffffffffc02040e8:	6098                	ld	a4,0(s1)
{
ffffffffc02040ea:	f406                	sd	ra,40(sp)
ffffffffc02040ec:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc02040ee:	02a70763          	beq	a4,a0,ffffffffc020411c <proc_run+0x40>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040f2:	100027f3          	csrr	a5,sstatus
ffffffffc02040f6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02040f8:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040fa:	ef85                	bnez	a5,ffffffffc0204132 <proc_run+0x56>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc02040fc:	755c                	ld	a5,168(a0)
ffffffffc02040fe:	56fd                	li	a3,-1
ffffffffc0204100:	16fe                	slli	a3,a3,0x3f
ffffffffc0204102:	83b1                	srli	a5,a5,0xc
         current = proc;
ffffffffc0204104:	e088                	sd	a0,0(s1)
ffffffffc0204106:	8fd5                	or	a5,a5,a3
ffffffffc0204108:	18079073          	csrw	satp,a5
         switch_to(&prev->context,&current->context);
ffffffffc020410c:	03050593          	addi	a1,a0,48
ffffffffc0204110:	03070513          	addi	a0,a4,48
ffffffffc0204114:	7f3000ef          	jal	ra,ffffffffc0205106 <switch_to>
    if (flag)
ffffffffc0204118:	00091763          	bnez	s2,ffffffffc0204126 <proc_run+0x4a>
}
ffffffffc020411c:	70a2                	ld	ra,40(sp)
ffffffffc020411e:	7482                	ld	s1,32(sp)
ffffffffc0204120:	6962                	ld	s2,24(sp)
ffffffffc0204122:	6145                	addi	sp,sp,48
ffffffffc0204124:	8082                	ret
ffffffffc0204126:	70a2                	ld	ra,40(sp)
ffffffffc0204128:	7482                	ld	s1,32(sp)
ffffffffc020412a:	6962                	ld	s2,24(sp)
ffffffffc020412c:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc020412e:	881fc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc0204132:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204134:	881fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
         struct proc_struct *prev = current;
ffffffffc0204138:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc020413a:	6522                	ld	a0,8(sp)
ffffffffc020413c:	4905                	li	s2,1
ffffffffc020413e:	bf7d                	j	ffffffffc02040fc <proc_run+0x20>

ffffffffc0204140 <do_fork>:
{
ffffffffc0204140:	7119                	addi	sp,sp,-128
ffffffffc0204142:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204144:	000a6917          	auipc	s2,0xa6
ffffffffc0204148:	5c490913          	addi	s2,s2,1476 # ffffffffc02aa708 <nr_process>
ffffffffc020414c:	00092703          	lw	a4,0(s2)
{
ffffffffc0204150:	fc86                	sd	ra,120(sp)
ffffffffc0204152:	f8a2                	sd	s0,112(sp)
ffffffffc0204154:	f4a6                	sd	s1,104(sp)
ffffffffc0204156:	ecce                	sd	s3,88(sp)
ffffffffc0204158:	e8d2                	sd	s4,80(sp)
ffffffffc020415a:	e4d6                	sd	s5,72(sp)
ffffffffc020415c:	e0da                	sd	s6,64(sp)
ffffffffc020415e:	fc5e                	sd	s7,56(sp)
ffffffffc0204160:	f862                	sd	s8,48(sp)
ffffffffc0204162:	f466                	sd	s9,40(sp)
ffffffffc0204164:	f06a                	sd	s10,32(sp)
ffffffffc0204166:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204168:	6785                	lui	a5,0x1
ffffffffc020416a:	2ef75c63          	bge	a4,a5,ffffffffc0204462 <do_fork+0x322>
ffffffffc020416e:	8a2a                	mv	s4,a0
ffffffffc0204170:	89ae                	mv	s3,a1
ffffffffc0204172:	8432                	mv	s0,a2
    proc = alloc_proc();
ffffffffc0204174:	df5ff0ef          	jal	ra,ffffffffc0203f68 <alloc_proc>
ffffffffc0204178:	84aa                	mv	s1,a0
    if(proc == NULL)
ffffffffc020417a:	2c050863          	beqz	a0,ffffffffc020444a <do_fork+0x30a>
    proc->parent = current;          // 父进程为当前进程
ffffffffc020417e:	000a6c17          	auipc	s8,0xa6
ffffffffc0204182:	572c0c13          	addi	s8,s8,1394 # ffffffffc02aa6f0 <current>
ffffffffc0204186:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020418a:	4509                	li	a0,2
    proc->parent = current;          // 父进程为当前进程
ffffffffc020418c:	f09c                	sd	a5,32(s1)
    current->wait_state = 0; // 确保当前进程的 wait_state 为 0
ffffffffc020418e:	0e07a623          	sw	zero,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8abc>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204192:	e2ffd0ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
    if (page != NULL)
ffffffffc0204196:	2a050763          	beqz	a0,ffffffffc0204444 <do_fork+0x304>
    return page - pages + nbase;
ffffffffc020419a:	000a6a97          	auipc	s5,0xa6
ffffffffc020419e:	53ea8a93          	addi	s5,s5,1342 # ffffffffc02aa6d8 <pages>
ffffffffc02041a2:	000ab683          	ld	a3,0(s5)
ffffffffc02041a6:	00003b17          	auipc	s6,0x3
ffffffffc02041aa:	7aab0b13          	addi	s6,s6,1962 # ffffffffc0207950 <nbase>
ffffffffc02041ae:	000b3783          	ld	a5,0(s6)
ffffffffc02041b2:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc02041b6:	000a6b97          	auipc	s7,0xa6
ffffffffc02041ba:	51ab8b93          	addi	s7,s7,1306 # ffffffffc02aa6d0 <npage>
    return page - pages + nbase;
ffffffffc02041be:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02041c0:	5dfd                	li	s11,-1
ffffffffc02041c2:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02041c6:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02041c8:	00cddd93          	srli	s11,s11,0xc
ffffffffc02041cc:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc02041d0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02041d2:	2ce67563          	bgeu	a2,a4,ffffffffc020449c <do_fork+0x35c>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc02041d6:	000c3603          	ld	a2,0(s8)
ffffffffc02041da:	000a6c17          	auipc	s8,0xa6
ffffffffc02041de:	50ec0c13          	addi	s8,s8,1294 # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc02041e2:	000c3703          	ld	a4,0(s8)
ffffffffc02041e6:	02863d03          	ld	s10,40(a2)
ffffffffc02041ea:	e43e                	sd	a5,8(sp)
ffffffffc02041ec:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02041ee:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc02041f0:	020d0863          	beqz	s10,ffffffffc0204220 <do_fork+0xe0>
    if (clone_flags & CLONE_VM)
ffffffffc02041f4:	100a7a13          	andi	s4,s4,256
ffffffffc02041f8:	180a0863          	beqz	s4,ffffffffc0204388 <do_fork+0x248>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc02041fc:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204200:	018d3783          	ld	a5,24(s10)
ffffffffc0204204:	c02006b7          	lui	a3,0xc0200
ffffffffc0204208:	2705                	addiw	a4,a4,1
ffffffffc020420a:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc020420e:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204212:	2ad7e163          	bltu	a5,a3,ffffffffc02044b4 <do_fork+0x374>
ffffffffc0204216:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020421a:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020421c:	8f99                	sub	a5,a5,a4
ffffffffc020421e:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204220:	6789                	lui	a5,0x2
ffffffffc0204222:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc8>
ffffffffc0204226:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204228:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020422a:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc020422c:	87b6                	mv	a5,a3
ffffffffc020422e:	12040893          	addi	a7,s0,288
ffffffffc0204232:	00063803          	ld	a6,0(a2)
ffffffffc0204236:	6608                	ld	a0,8(a2)
ffffffffc0204238:	6a0c                	ld	a1,16(a2)
ffffffffc020423a:	6e18                	ld	a4,24(a2)
ffffffffc020423c:	0107b023          	sd	a6,0(a5)
ffffffffc0204240:	e788                	sd	a0,8(a5)
ffffffffc0204242:	eb8c                	sd	a1,16(a5)
ffffffffc0204244:	ef98                	sd	a4,24(a5)
ffffffffc0204246:	02060613          	addi	a2,a2,32
ffffffffc020424a:	02078793          	addi	a5,a5,32
ffffffffc020424e:	ff1612e3          	bne	a2,a7,ffffffffc0204232 <do_fork+0xf2>
    proc->tf->gpr.a0 = 0;
ffffffffc0204252:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204256:	12098763          	beqz	s3,ffffffffc0204384 <do_fork+0x244>
    if (++last_pid >= MAX_PID)
ffffffffc020425a:	000a2817          	auipc	a6,0xa2
ffffffffc020425e:	00680813          	addi	a6,a6,6 # ffffffffc02a6260 <last_pid.1>
ffffffffc0204262:	00082783          	lw	a5,0(a6)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204266:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020426a:	00000717          	auipc	a4,0x0
ffffffffc020426e:	d7070713          	addi	a4,a4,-656 # ffffffffc0203fda <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc0204272:	0017851b          	addiw	a0,a5,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204276:	f898                	sd	a4,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204278:	fc94                	sd	a3,56(s1)
    if (++last_pid >= MAX_PID)
ffffffffc020427a:	00a82023          	sw	a0,0(a6)
ffffffffc020427e:	6789                	lui	a5,0x2
ffffffffc0204280:	08f55b63          	bge	a0,a5,ffffffffc0204316 <do_fork+0x1d6>
    if (last_pid >= next_safe)
ffffffffc0204284:	000a2317          	auipc	t1,0xa2
ffffffffc0204288:	fe030313          	addi	t1,t1,-32 # ffffffffc02a6264 <next_safe.0>
ffffffffc020428c:	00032783          	lw	a5,0(t1)
ffffffffc0204290:	000a6417          	auipc	s0,0xa6
ffffffffc0204294:	3f040413          	addi	s0,s0,1008 # ffffffffc02aa680 <proc_list>
ffffffffc0204298:	08f55763          	bge	a0,a5,ffffffffc0204326 <do_fork+0x1e6>
    proc->pid = get_pid();           // 分配唯一 PID
ffffffffc020429c:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020429e:	45a9                	li	a1,10
ffffffffc02042a0:	2501                	sext.w	a0,a0
ffffffffc02042a2:	0ba010ef          	jal	ra,ffffffffc020535c <hash32>
ffffffffc02042a6:	02051793          	slli	a5,a0,0x20
ffffffffc02042aa:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02042ae:	000a2797          	auipc	a5,0xa2
ffffffffc02042b2:	3d278793          	addi	a5,a5,978 # ffffffffc02a6680 <hash_list>
ffffffffc02042b6:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02042b8:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02042ba:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02042bc:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc02042c0:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02042c2:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc02042c4:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02042c6:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02042c8:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc02042cc:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc02042ce:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc02042d0:	e21c                	sd	a5,0(a2)
ffffffffc02042d2:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc02042d4:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc02042d6:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc02042d8:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02042dc:	10e4b023          	sd	a4,256(s1)
ffffffffc02042e0:	c311                	beqz	a4,ffffffffc02042e4 <do_fork+0x1a4>
        proc->optr->yptr = proc;
ffffffffc02042e2:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc02042e4:	00092783          	lw	a5,0(s2)
    wakeup_proc(proc);
ffffffffc02042e8:	8526                	mv	a0,s1
    proc->parent->cptr = proc;
ffffffffc02042ea:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc02042ec:	2785                	addiw	a5,a5,1
ffffffffc02042ee:	00f92023          	sw	a5,0(s2)
    wakeup_proc(proc);
ffffffffc02042f2:	67f000ef          	jal	ra,ffffffffc0205170 <wakeup_proc>
    ret = proc->pid;
ffffffffc02042f6:	40c8                	lw	a0,4(s1)
}
ffffffffc02042f8:	70e6                	ld	ra,120(sp)
ffffffffc02042fa:	7446                	ld	s0,112(sp)
ffffffffc02042fc:	74a6                	ld	s1,104(sp)
ffffffffc02042fe:	7906                	ld	s2,96(sp)
ffffffffc0204300:	69e6                	ld	s3,88(sp)
ffffffffc0204302:	6a46                	ld	s4,80(sp)
ffffffffc0204304:	6aa6                	ld	s5,72(sp)
ffffffffc0204306:	6b06                	ld	s6,64(sp)
ffffffffc0204308:	7be2                	ld	s7,56(sp)
ffffffffc020430a:	7c42                	ld	s8,48(sp)
ffffffffc020430c:	7ca2                	ld	s9,40(sp)
ffffffffc020430e:	7d02                	ld	s10,32(sp)
ffffffffc0204310:	6de2                	ld	s11,24(sp)
ffffffffc0204312:	6109                	addi	sp,sp,128
ffffffffc0204314:	8082                	ret
        last_pid = 1;
ffffffffc0204316:	4785                	li	a5,1
ffffffffc0204318:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020431c:	4505                	li	a0,1
ffffffffc020431e:	000a2317          	auipc	t1,0xa2
ffffffffc0204322:	f4630313          	addi	t1,t1,-186 # ffffffffc02a6264 <next_safe.0>
    return listelm->next;
ffffffffc0204326:	000a6417          	auipc	s0,0xa6
ffffffffc020432a:	35a40413          	addi	s0,s0,858 # ffffffffc02aa680 <proc_list>
ffffffffc020432e:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0204332:	6789                	lui	a5,0x2
ffffffffc0204334:	00f32023          	sw	a5,0(t1)
ffffffffc0204338:	86aa                	mv	a3,a0
ffffffffc020433a:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020433c:	6e89                	lui	t4,0x2
ffffffffc020433e:	108e0d63          	beq	t3,s0,ffffffffc0204458 <do_fork+0x318>
ffffffffc0204342:	88ae                	mv	a7,a1
ffffffffc0204344:	87f2                	mv	a5,t3
ffffffffc0204346:	6609                	lui	a2,0x2
ffffffffc0204348:	a811                	j	ffffffffc020435c <do_fork+0x21c>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020434a:	00e6d663          	bge	a3,a4,ffffffffc0204356 <do_fork+0x216>
ffffffffc020434e:	00c75463          	bge	a4,a2,ffffffffc0204356 <do_fork+0x216>
ffffffffc0204352:	863a                	mv	a2,a4
ffffffffc0204354:	4885                	li	a7,1
ffffffffc0204356:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204358:	00878d63          	beq	a5,s0,ffffffffc0204372 <do_fork+0x232>
            if (proc->pid == last_pid)
ffffffffc020435c:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c6c>
ffffffffc0204360:	fed715e3          	bne	a4,a3,ffffffffc020434a <do_fork+0x20a>
                if (++last_pid >= next_safe)
ffffffffc0204364:	2685                	addiw	a3,a3,1
ffffffffc0204366:	0ec6d463          	bge	a3,a2,ffffffffc020444e <do_fork+0x30e>
ffffffffc020436a:	679c                	ld	a5,8(a5)
ffffffffc020436c:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc020436e:	fe8797e3          	bne	a5,s0,ffffffffc020435c <do_fork+0x21c>
ffffffffc0204372:	c581                	beqz	a1,ffffffffc020437a <do_fork+0x23a>
ffffffffc0204374:	00d82023          	sw	a3,0(a6)
ffffffffc0204378:	8536                	mv	a0,a3
ffffffffc020437a:	f20881e3          	beqz	a7,ffffffffc020429c <do_fork+0x15c>
ffffffffc020437e:	00c32023          	sw	a2,0(t1)
ffffffffc0204382:	bf29                	j	ffffffffc020429c <do_fork+0x15c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204384:	89b6                	mv	s3,a3
ffffffffc0204386:	bdd1                	j	ffffffffc020425a <do_fork+0x11a>
    if ((mm = mm_create()) == NULL)
ffffffffc0204388:	cceff0ef          	jal	ra,ffffffffc0203856 <mm_create>
ffffffffc020438c:	8caa                	mv	s9,a0
ffffffffc020438e:	c159                	beqz	a0,ffffffffc0204414 <do_fork+0x2d4>
    if ((page = alloc_page()) == NULL)
ffffffffc0204390:	4505                	li	a0,1
ffffffffc0204392:	c2ffd0ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc0204396:	cd25                	beqz	a0,ffffffffc020440e <do_fork+0x2ce>
    return page - pages + nbase;
ffffffffc0204398:	000ab683          	ld	a3,0(s5)
ffffffffc020439c:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc020439e:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02043a2:	40d506b3          	sub	a3,a0,a3
ffffffffc02043a6:	8699                	srai	a3,a3,0x6
ffffffffc02043a8:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02043aa:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc02043ae:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02043b0:	0eedf663          	bgeu	s11,a4,ffffffffc020449c <do_fork+0x35c>
ffffffffc02043b4:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02043b8:	6605                	lui	a2,0x1
ffffffffc02043ba:	000a6597          	auipc	a1,0xa6
ffffffffc02043be:	30e5b583          	ld	a1,782(a1) # ffffffffc02aa6c8 <boot_pgdir_va>
ffffffffc02043c2:	9a36                	add	s4,s4,a3
ffffffffc02043c4:	8552                	mv	a0,s4
ffffffffc02043c6:	44e010ef          	jal	ra,ffffffffc0205814 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02043ca:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc02043ce:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02043d2:	4785                	li	a5,1
ffffffffc02043d4:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc02043d8:	8b85                	andi	a5,a5,1
ffffffffc02043da:	4a05                	li	s4,1
ffffffffc02043dc:	c799                	beqz	a5,ffffffffc02043ea <do_fork+0x2aa>
    {
        schedule();
ffffffffc02043de:	613000ef          	jal	ra,ffffffffc02051f0 <schedule>
ffffffffc02043e2:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc02043e6:	8b85                	andi	a5,a5,1
ffffffffc02043e8:	fbfd                	bnez	a5,ffffffffc02043de <do_fork+0x29e>
        ret = dup_mmap(mm, oldmm);
ffffffffc02043ea:	85ea                	mv	a1,s10
ffffffffc02043ec:	8566                	mv	a0,s9
ffffffffc02043ee:	eaaff0ef          	jal	ra,ffffffffc0203a98 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02043f2:	57f9                	li	a5,-2
ffffffffc02043f4:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc02043f8:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc02043fa:	cbad                	beqz	a5,ffffffffc020446c <do_fork+0x32c>
good_mm:
ffffffffc02043fc:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc02043fe:	de050fe3          	beqz	a0,ffffffffc02041fc <do_fork+0xbc>
    exit_mmap(mm);
ffffffffc0204402:	8566                	mv	a0,s9
ffffffffc0204404:	f2eff0ef          	jal	ra,ffffffffc0203b32 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204408:	8566                	mv	a0,s9
ffffffffc020440a:	c5dff0ef          	jal	ra,ffffffffc0204066 <put_pgdir>
    mm_destroy(mm);
ffffffffc020440e:	8566                	mv	a0,s9
ffffffffc0204410:	d86ff0ef          	jal	ra,ffffffffc0203996 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204414:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc0204416:	c02007b7          	lui	a5,0xc0200
ffffffffc020441a:	0af6ea63          	bltu	a3,a5,ffffffffc02044ce <do_fork+0x38e>
ffffffffc020441e:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc0204422:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc0204426:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020442a:	83b1                	srli	a5,a5,0xc
ffffffffc020442c:	04e7fc63          	bgeu	a5,a4,ffffffffc0204484 <do_fork+0x344>
    return &pages[PPN(pa) - nbase];
ffffffffc0204430:	000b3703          	ld	a4,0(s6)
ffffffffc0204434:	000ab503          	ld	a0,0(s5)
ffffffffc0204438:	4589                	li	a1,2
ffffffffc020443a:	8f99                	sub	a5,a5,a4
ffffffffc020443c:	079a                	slli	a5,a5,0x6
ffffffffc020443e:	953e                	add	a0,a0,a5
ffffffffc0204440:	bbffd0ef          	jal	ra,ffffffffc0201ffe <free_pages>
    kfree(proc);
ffffffffc0204444:	8526                	mv	a0,s1
ffffffffc0204446:	a4dfd0ef          	jal	ra,ffffffffc0201e92 <kfree>
    ret = -E_NO_MEM;
ffffffffc020444a:	5571                	li	a0,-4
    return ret;
ffffffffc020444c:	b575                	j	ffffffffc02042f8 <do_fork+0x1b8>
                    if (last_pid >= MAX_PID)
ffffffffc020444e:	01d6c363          	blt	a3,t4,ffffffffc0204454 <do_fork+0x314>
                        last_pid = 1;
ffffffffc0204452:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204454:	4585                	li	a1,1
ffffffffc0204456:	b5e5                	j	ffffffffc020433e <do_fork+0x1fe>
ffffffffc0204458:	c599                	beqz	a1,ffffffffc0204466 <do_fork+0x326>
ffffffffc020445a:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc020445e:	8536                	mv	a0,a3
ffffffffc0204460:	bd35                	j	ffffffffc020429c <do_fork+0x15c>
    int ret = -E_NO_FREE_PROC;
ffffffffc0204462:	556d                	li	a0,-5
ffffffffc0204464:	bd51                	j	ffffffffc02042f8 <do_fork+0x1b8>
    return last_pid;
ffffffffc0204466:	00082503          	lw	a0,0(a6)
ffffffffc020446a:	bd0d                	j	ffffffffc020429c <do_fork+0x15c>
    {
        panic("Unlock failed.\n");
ffffffffc020446c:	00003617          	auipc	a2,0x3
ffffffffc0204470:	c6460613          	addi	a2,a2,-924 # ffffffffc02070d0 <default_pmm_manager+0xa30>
ffffffffc0204474:	03f00593          	li	a1,63
ffffffffc0204478:	00003517          	auipc	a0,0x3
ffffffffc020447c:	c6850513          	addi	a0,a0,-920 # ffffffffc02070e0 <default_pmm_manager+0xa40>
ffffffffc0204480:	80efc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204484:	00002617          	auipc	a2,0x2
ffffffffc0204488:	2ec60613          	addi	a2,a2,748 # ffffffffc0206770 <default_pmm_manager+0xd0>
ffffffffc020448c:	06900593          	li	a1,105
ffffffffc0204490:	00002517          	auipc	a0,0x2
ffffffffc0204494:	de050513          	addi	a0,a0,-544 # ffffffffc0206270 <commands+0x7d8>
ffffffffc0204498:	ff7fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc020449c:	00002617          	auipc	a2,0x2
ffffffffc02044a0:	dac60613          	addi	a2,a2,-596 # ffffffffc0206248 <commands+0x7b0>
ffffffffc02044a4:	07100593          	li	a1,113
ffffffffc02044a8:	00002517          	auipc	a0,0x2
ffffffffc02044ac:	dc850513          	addi	a0,a0,-568 # ffffffffc0206270 <commands+0x7d8>
ffffffffc02044b0:	fdffb0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02044b4:	86be                	mv	a3,a5
ffffffffc02044b6:	00002617          	auipc	a2,0x2
ffffffffc02044ba:	29260613          	addi	a2,a2,658 # ffffffffc0206748 <default_pmm_manager+0xa8>
ffffffffc02044be:	18b00593          	li	a1,395
ffffffffc02044c2:	00003517          	auipc	a0,0x3
ffffffffc02044c6:	bf650513          	addi	a0,a0,-1034 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc02044ca:	fc5fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc02044ce:	00002617          	auipc	a2,0x2
ffffffffc02044d2:	27a60613          	addi	a2,a2,634 # ffffffffc0206748 <default_pmm_manager+0xa8>
ffffffffc02044d6:	07700593          	li	a1,119
ffffffffc02044da:	00002517          	auipc	a0,0x2
ffffffffc02044de:	d9650513          	addi	a0,a0,-618 # ffffffffc0206270 <commands+0x7d8>
ffffffffc02044e2:	fadfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02044e6 <kernel_thread>:
{
ffffffffc02044e6:	7129                	addi	sp,sp,-320
ffffffffc02044e8:	fa22                	sd	s0,304(sp)
ffffffffc02044ea:	f626                	sd	s1,296(sp)
ffffffffc02044ec:	f24a                	sd	s2,288(sp)
ffffffffc02044ee:	84ae                	mv	s1,a1
ffffffffc02044f0:	892a                	mv	s2,a0
ffffffffc02044f2:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02044f4:	4581                	li	a1,0
ffffffffc02044f6:	12000613          	li	a2,288
ffffffffc02044fa:	850a                	mv	a0,sp
{
ffffffffc02044fc:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02044fe:	304010ef          	jal	ra,ffffffffc0205802 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204502:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204504:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204506:	100027f3          	csrr	a5,sstatus
ffffffffc020450a:	edd7f793          	andi	a5,a5,-291
ffffffffc020450e:	1207e793          	ori	a5,a5,288
ffffffffc0204512:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204514:	860a                	mv	a2,sp
ffffffffc0204516:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020451a:	00000797          	auipc	a5,0x0
ffffffffc020451e:	a4678793          	addi	a5,a5,-1466 # ffffffffc0203f60 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204522:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204524:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204526:	c1bff0ef          	jal	ra,ffffffffc0204140 <do_fork>
}
ffffffffc020452a:	70f2                	ld	ra,312(sp)
ffffffffc020452c:	7452                	ld	s0,304(sp)
ffffffffc020452e:	74b2                	ld	s1,296(sp)
ffffffffc0204530:	7912                	ld	s2,288(sp)
ffffffffc0204532:	6131                	addi	sp,sp,320
ffffffffc0204534:	8082                	ret

ffffffffc0204536 <do_exit>:
{
ffffffffc0204536:	7179                	addi	sp,sp,-48
ffffffffc0204538:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc020453a:	000a6417          	auipc	s0,0xa6
ffffffffc020453e:	1b640413          	addi	s0,s0,438 # ffffffffc02aa6f0 <current>
ffffffffc0204542:	601c                	ld	a5,0(s0)
{
ffffffffc0204544:	f406                	sd	ra,40(sp)
ffffffffc0204546:	ec26                	sd	s1,24(sp)
ffffffffc0204548:	e84a                	sd	s2,16(sp)
ffffffffc020454a:	e44e                	sd	s3,8(sp)
ffffffffc020454c:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc020454e:	000a6717          	auipc	a4,0xa6
ffffffffc0204552:	1aa73703          	ld	a4,426(a4) # ffffffffc02aa6f8 <idleproc>
ffffffffc0204556:	0ce78c63          	beq	a5,a4,ffffffffc020462e <do_exit+0xf8>
    if (current == initproc)
ffffffffc020455a:	000a6497          	auipc	s1,0xa6
ffffffffc020455e:	1a648493          	addi	s1,s1,422 # ffffffffc02aa700 <initproc>
ffffffffc0204562:	6098                	ld	a4,0(s1)
ffffffffc0204564:	0ee78b63          	beq	a5,a4,ffffffffc020465a <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc0204568:	0287b983          	ld	s3,40(a5)
ffffffffc020456c:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc020456e:	02098663          	beqz	s3,ffffffffc020459a <do_exit+0x64>
ffffffffc0204572:	000a6797          	auipc	a5,0xa6
ffffffffc0204576:	14e7b783          	ld	a5,334(a5) # ffffffffc02aa6c0 <boot_pgdir_pa>
ffffffffc020457a:	577d                	li	a4,-1
ffffffffc020457c:	177e                	slli	a4,a4,0x3f
ffffffffc020457e:	83b1                	srli	a5,a5,0xc
ffffffffc0204580:	8fd9                	or	a5,a5,a4
ffffffffc0204582:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204586:	0309a783          	lw	a5,48(s3)
ffffffffc020458a:	fff7871b          	addiw	a4,a5,-1
ffffffffc020458e:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204592:	cb55                	beqz	a4,ffffffffc0204646 <do_exit+0x110>
        current->mm = NULL;
ffffffffc0204594:	601c                	ld	a5,0(s0)
ffffffffc0204596:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc020459a:	601c                	ld	a5,0(s0)
ffffffffc020459c:	470d                	li	a4,3
ffffffffc020459e:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02045a0:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045a4:	100027f3          	csrr	a5,sstatus
ffffffffc02045a8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02045aa:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02045ac:	e3f9                	bnez	a5,ffffffffc0204672 <do_exit+0x13c>
        proc = current->parent;
ffffffffc02045ae:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc02045b0:	800007b7          	lui	a5,0x80000
ffffffffc02045b4:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc02045b6:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc02045b8:	0ec52703          	lw	a4,236(a0)
ffffffffc02045bc:	0af70f63          	beq	a4,a5,ffffffffc020467a <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc02045c0:	6018                	ld	a4,0(s0)
ffffffffc02045c2:	7b7c                	ld	a5,240(a4)
ffffffffc02045c4:	c3a1                	beqz	a5,ffffffffc0204604 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02045c6:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045ca:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc02045cc:	0985                	addi	s3,s3,1
ffffffffc02045ce:	a021                	j	ffffffffc02045d6 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc02045d0:	6018                	ld	a4,0(s0)
ffffffffc02045d2:	7b7c                	ld	a5,240(a4)
ffffffffc02045d4:	cb85                	beqz	a5,ffffffffc0204604 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc02045d6:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fe0>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02045da:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc02045dc:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02045de:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc02045e0:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02045e4:	10e7b023          	sd	a4,256(a5)
ffffffffc02045e8:	c311                	beqz	a4,ffffffffc02045ec <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc02045ea:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045ec:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc02045ee:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc02045f0:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045f2:	fd271fe3          	bne	a4,s2,ffffffffc02045d0 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02045f6:	0ec52783          	lw	a5,236(a0)
ffffffffc02045fa:	fd379be3          	bne	a5,s3,ffffffffc02045d0 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc02045fe:	373000ef          	jal	ra,ffffffffc0205170 <wakeup_proc>
ffffffffc0204602:	b7f9                	j	ffffffffc02045d0 <do_exit+0x9a>
    if (flag)
ffffffffc0204604:	020a1263          	bnez	s4,ffffffffc0204628 <do_exit+0xf2>
    schedule();
ffffffffc0204608:	3e9000ef          	jal	ra,ffffffffc02051f0 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc020460c:	601c                	ld	a5,0(s0)
ffffffffc020460e:	00003617          	auipc	a2,0x3
ffffffffc0204612:	b0a60613          	addi	a2,a2,-1270 # ffffffffc0207118 <default_pmm_manager+0xa78>
ffffffffc0204616:	23300593          	li	a1,563
ffffffffc020461a:	43d4                	lw	a3,4(a5)
ffffffffc020461c:	00003517          	auipc	a0,0x3
ffffffffc0204620:	a9c50513          	addi	a0,a0,-1380 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0204624:	e6bfb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc0204628:	b86fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020462c:	bff1                	j	ffffffffc0204608 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc020462e:	00003617          	auipc	a2,0x3
ffffffffc0204632:	aca60613          	addi	a2,a2,-1334 # ffffffffc02070f8 <default_pmm_manager+0xa58>
ffffffffc0204636:	1ff00593          	li	a1,511
ffffffffc020463a:	00003517          	auipc	a0,0x3
ffffffffc020463e:	a7e50513          	addi	a0,a0,-1410 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0204642:	e4dfb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc0204646:	854e                	mv	a0,s3
ffffffffc0204648:	ceaff0ef          	jal	ra,ffffffffc0203b32 <exit_mmap>
            put_pgdir(mm);
ffffffffc020464c:	854e                	mv	a0,s3
ffffffffc020464e:	a19ff0ef          	jal	ra,ffffffffc0204066 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204652:	854e                	mv	a0,s3
ffffffffc0204654:	b42ff0ef          	jal	ra,ffffffffc0203996 <mm_destroy>
ffffffffc0204658:	bf35                	j	ffffffffc0204594 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc020465a:	00003617          	auipc	a2,0x3
ffffffffc020465e:	aae60613          	addi	a2,a2,-1362 # ffffffffc0207108 <default_pmm_manager+0xa68>
ffffffffc0204662:	20300593          	li	a1,515
ffffffffc0204666:	00003517          	auipc	a0,0x3
ffffffffc020466a:	a5250513          	addi	a0,a0,-1454 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc020466e:	e21fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc0204672:	b42fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204676:	4a05                	li	s4,1
ffffffffc0204678:	bf1d                	j	ffffffffc02045ae <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc020467a:	2f7000ef          	jal	ra,ffffffffc0205170 <wakeup_proc>
ffffffffc020467e:	b789                	j	ffffffffc02045c0 <do_exit+0x8a>

ffffffffc0204680 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc0204680:	715d                	addi	sp,sp,-80
ffffffffc0204682:	f84a                	sd	s2,48(sp)
ffffffffc0204684:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc0204686:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc020468a:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc020468c:	fc26                	sd	s1,56(sp)
ffffffffc020468e:	f052                	sd	s4,32(sp)
ffffffffc0204690:	ec56                	sd	s5,24(sp)
ffffffffc0204692:	e85a                	sd	s6,16(sp)
ffffffffc0204694:	e45e                	sd	s7,8(sp)
ffffffffc0204696:	e486                	sd	ra,72(sp)
ffffffffc0204698:	e0a2                	sd	s0,64(sp)
ffffffffc020469a:	84aa                	mv	s1,a0
ffffffffc020469c:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc020469e:	000a6b97          	auipc	s7,0xa6
ffffffffc02046a2:	052b8b93          	addi	s7,s7,82 # ffffffffc02aa6f0 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc02046a6:	00050b1b          	sext.w	s6,a0
ffffffffc02046aa:	fff50a9b          	addiw	s5,a0,-1
ffffffffc02046ae:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc02046b0:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc02046b2:	ccbd                	beqz	s1,ffffffffc0204730 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc02046b4:	0359e863          	bltu	s3,s5,ffffffffc02046e4 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02046b8:	45a9                	li	a1,10
ffffffffc02046ba:	855a                	mv	a0,s6
ffffffffc02046bc:	4a1000ef          	jal	ra,ffffffffc020535c <hash32>
ffffffffc02046c0:	02051793          	slli	a5,a0,0x20
ffffffffc02046c4:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02046c8:	000a2797          	auipc	a5,0xa2
ffffffffc02046cc:	fb878793          	addi	a5,a5,-72 # ffffffffc02a6680 <hash_list>
ffffffffc02046d0:	953e                	add	a0,a0,a5
ffffffffc02046d2:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc02046d4:	a029                	j	ffffffffc02046de <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc02046d6:	f2c42783          	lw	a5,-212(s0)
ffffffffc02046da:	02978163          	beq	a5,s1,ffffffffc02046fc <do_wait.part.0+0x7c>
ffffffffc02046de:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc02046e0:	fe851be3          	bne	a0,s0,ffffffffc02046d6 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc02046e4:	5579                	li	a0,-2
}
ffffffffc02046e6:	60a6                	ld	ra,72(sp)
ffffffffc02046e8:	6406                	ld	s0,64(sp)
ffffffffc02046ea:	74e2                	ld	s1,56(sp)
ffffffffc02046ec:	7942                	ld	s2,48(sp)
ffffffffc02046ee:	79a2                	ld	s3,40(sp)
ffffffffc02046f0:	7a02                	ld	s4,32(sp)
ffffffffc02046f2:	6ae2                	ld	s5,24(sp)
ffffffffc02046f4:	6b42                	ld	s6,16(sp)
ffffffffc02046f6:	6ba2                	ld	s7,8(sp)
ffffffffc02046f8:	6161                	addi	sp,sp,80
ffffffffc02046fa:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc02046fc:	000bb683          	ld	a3,0(s7)
ffffffffc0204700:	f4843783          	ld	a5,-184(s0)
ffffffffc0204704:	fed790e3          	bne	a5,a3,ffffffffc02046e4 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204708:	f2842703          	lw	a4,-216(s0)
ffffffffc020470c:	478d                	li	a5,3
ffffffffc020470e:	0ef70b63          	beq	a4,a5,ffffffffc0204804 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0204712:	4785                	li	a5,1
ffffffffc0204714:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0204716:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc020471a:	2d7000ef          	jal	ra,ffffffffc02051f0 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc020471e:	000bb783          	ld	a5,0(s7)
ffffffffc0204722:	0b07a783          	lw	a5,176(a5)
ffffffffc0204726:	8b85                	andi	a5,a5,1
ffffffffc0204728:	d7c9                	beqz	a5,ffffffffc02046b2 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc020472a:	555d                	li	a0,-9
ffffffffc020472c:	e0bff0ef          	jal	ra,ffffffffc0204536 <do_exit>
        proc = current->cptr;
ffffffffc0204730:	000bb683          	ld	a3,0(s7)
ffffffffc0204734:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204736:	d45d                	beqz	s0,ffffffffc02046e4 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204738:	470d                	li	a4,3
ffffffffc020473a:	a021                	j	ffffffffc0204742 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc020473c:	10043403          	ld	s0,256(s0)
ffffffffc0204740:	d869                	beqz	s0,ffffffffc0204712 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204742:	401c                	lw	a5,0(s0)
ffffffffc0204744:	fee79ce3          	bne	a5,a4,ffffffffc020473c <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc0204748:	000a6797          	auipc	a5,0xa6
ffffffffc020474c:	fb07b783          	ld	a5,-80(a5) # ffffffffc02aa6f8 <idleproc>
ffffffffc0204750:	0c878963          	beq	a5,s0,ffffffffc0204822 <do_wait.part.0+0x1a2>
ffffffffc0204754:	000a6797          	auipc	a5,0xa6
ffffffffc0204758:	fac7b783          	ld	a5,-84(a5) # ffffffffc02aa700 <initproc>
ffffffffc020475c:	0cf40363          	beq	s0,a5,ffffffffc0204822 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc0204760:	000a0663          	beqz	s4,ffffffffc020476c <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204764:	0e842783          	lw	a5,232(s0)
ffffffffc0204768:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020476c:	100027f3          	csrr	a5,sstatus
ffffffffc0204770:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204772:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204774:	e7c1                	bnez	a5,ffffffffc02047fc <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204776:	6c70                	ld	a2,216(s0)
ffffffffc0204778:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc020477a:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc020477e:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0204780:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204782:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204784:	6470                	ld	a2,200(s0)
ffffffffc0204786:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0204788:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc020478a:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc020478c:	c319                	beqz	a4,ffffffffc0204792 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc020478e:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc0204790:	7c7c                	ld	a5,248(s0)
ffffffffc0204792:	c3b5                	beqz	a5,ffffffffc02047f6 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc0204794:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc0204798:	000a6717          	auipc	a4,0xa6
ffffffffc020479c:	f7070713          	addi	a4,a4,-144 # ffffffffc02aa708 <nr_process>
ffffffffc02047a0:	431c                	lw	a5,0(a4)
ffffffffc02047a2:	37fd                	addiw	a5,a5,-1
ffffffffc02047a4:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc02047a6:	e5a9                	bnez	a1,ffffffffc02047f0 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02047a8:	6814                	ld	a3,16(s0)
ffffffffc02047aa:	c02007b7          	lui	a5,0xc0200
ffffffffc02047ae:	04f6ee63          	bltu	a3,a5,ffffffffc020480a <do_wait.part.0+0x18a>
ffffffffc02047b2:	000a6797          	auipc	a5,0xa6
ffffffffc02047b6:	f367b783          	ld	a5,-202(a5) # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc02047ba:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02047bc:	82b1                	srli	a3,a3,0xc
ffffffffc02047be:	000a6797          	auipc	a5,0xa6
ffffffffc02047c2:	f127b783          	ld	a5,-238(a5) # ffffffffc02aa6d0 <npage>
ffffffffc02047c6:	06f6fa63          	bgeu	a3,a5,ffffffffc020483a <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc02047ca:	00003517          	auipc	a0,0x3
ffffffffc02047ce:	18653503          	ld	a0,390(a0) # ffffffffc0207950 <nbase>
ffffffffc02047d2:	8e89                	sub	a3,a3,a0
ffffffffc02047d4:	069a                	slli	a3,a3,0x6
ffffffffc02047d6:	000a6517          	auipc	a0,0xa6
ffffffffc02047da:	f0253503          	ld	a0,-254(a0) # ffffffffc02aa6d8 <pages>
ffffffffc02047de:	9536                	add	a0,a0,a3
ffffffffc02047e0:	4589                	li	a1,2
ffffffffc02047e2:	81dfd0ef          	jal	ra,ffffffffc0201ffe <free_pages>
    kfree(proc);
ffffffffc02047e6:	8522                	mv	a0,s0
ffffffffc02047e8:	eaafd0ef          	jal	ra,ffffffffc0201e92 <kfree>
    return 0;
ffffffffc02047ec:	4501                	li	a0,0
ffffffffc02047ee:	bde5                	j	ffffffffc02046e6 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc02047f0:	9befc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02047f4:	bf55                	j	ffffffffc02047a8 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc02047f6:	701c                	ld	a5,32(s0)
ffffffffc02047f8:	fbf8                	sd	a4,240(a5)
ffffffffc02047fa:	bf79                	j	ffffffffc0204798 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc02047fc:	9b8fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204800:	4585                	li	a1,1
ffffffffc0204802:	bf95                	j	ffffffffc0204776 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204804:	f2840413          	addi	s0,s0,-216
ffffffffc0204808:	b781                	j	ffffffffc0204748 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc020480a:	00002617          	auipc	a2,0x2
ffffffffc020480e:	f3e60613          	addi	a2,a2,-194 # ffffffffc0206748 <default_pmm_manager+0xa8>
ffffffffc0204812:	07700593          	li	a1,119
ffffffffc0204816:	00002517          	auipc	a0,0x2
ffffffffc020481a:	a5a50513          	addi	a0,a0,-1446 # ffffffffc0206270 <commands+0x7d8>
ffffffffc020481e:	c71fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0204822:	00003617          	auipc	a2,0x3
ffffffffc0204826:	91660613          	addi	a2,a2,-1770 # ffffffffc0207138 <default_pmm_manager+0xa98>
ffffffffc020482a:	35500593          	li	a1,853
ffffffffc020482e:	00003517          	auipc	a0,0x3
ffffffffc0204832:	88a50513          	addi	a0,a0,-1910 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0204836:	c59fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020483a:	00002617          	auipc	a2,0x2
ffffffffc020483e:	f3660613          	addi	a2,a2,-202 # ffffffffc0206770 <default_pmm_manager+0xd0>
ffffffffc0204842:	06900593          	li	a1,105
ffffffffc0204846:	00002517          	auipc	a0,0x2
ffffffffc020484a:	a2a50513          	addi	a0,a0,-1494 # ffffffffc0206270 <commands+0x7d8>
ffffffffc020484e:	c41fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204852 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0204852:	1141                	addi	sp,sp,-16
ffffffffc0204854:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204856:	fe8fd0ef          	jal	ra,ffffffffc020203e <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc020485a:	d84fd0ef          	jal	ra,ffffffffc0201dde <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);//创建了新的进程
ffffffffc020485e:	4601                	li	a2,0
ffffffffc0204860:	4581                	li	a1,0
ffffffffc0204862:	fffff517          	auipc	a0,0xfffff
ffffffffc0204866:	78650513          	addi	a0,a0,1926 # ffffffffc0203fe8 <user_main>
ffffffffc020486a:	c7dff0ef          	jal	ra,ffffffffc02044e6 <kernel_thread>
    if (pid <= 0)
ffffffffc020486e:	00a04563          	bgtz	a0,ffffffffc0204878 <init_main+0x26>
ffffffffc0204872:	a071                	j	ffffffffc02048fe <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0) //只要还能成功回收一个子进程，就继续循环;另一种情况是do_wait中，如果父进程没有僵尸状态的紫禁城，那么触发调度
    {
        schedule();
ffffffffc0204874:	17d000ef          	jal	ra,ffffffffc02051f0 <schedule>
    if (code_store != NULL)
ffffffffc0204878:	4581                	li	a1,0
ffffffffc020487a:	4501                	li	a0,0
ffffffffc020487c:	e05ff0ef          	jal	ra,ffffffffc0204680 <do_wait.part.0>
    while (do_wait(0, NULL) == 0) //只要还能成功回收一个子进程，就继续循环;另一种情况是do_wait中，如果父进程没有僵尸状态的紫禁城，那么触发调度
ffffffffc0204880:	d975                	beqz	a0,ffffffffc0204874 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204882:	00003517          	auipc	a0,0x3
ffffffffc0204886:	8f650513          	addi	a0,a0,-1802 # ffffffffc0207178 <default_pmm_manager+0xad8>
ffffffffc020488a:	90bfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020488e:	000a6797          	auipc	a5,0xa6
ffffffffc0204892:	e727b783          	ld	a5,-398(a5) # ffffffffc02aa700 <initproc>
ffffffffc0204896:	7bf8                	ld	a4,240(a5)
ffffffffc0204898:	e339                	bnez	a4,ffffffffc02048de <init_main+0x8c>
ffffffffc020489a:	7ff8                	ld	a4,248(a5)
ffffffffc020489c:	e329                	bnez	a4,ffffffffc02048de <init_main+0x8c>
ffffffffc020489e:	1007b703          	ld	a4,256(a5)
ffffffffc02048a2:	ef15                	bnez	a4,ffffffffc02048de <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc02048a4:	000a6697          	auipc	a3,0xa6
ffffffffc02048a8:	e646a683          	lw	a3,-412(a3) # ffffffffc02aa708 <nr_process>
ffffffffc02048ac:	4709                	li	a4,2
ffffffffc02048ae:	0ae69463          	bne	a3,a4,ffffffffc0204956 <init_main+0x104>
    return listelm->next;
ffffffffc02048b2:	000a6697          	auipc	a3,0xa6
ffffffffc02048b6:	dce68693          	addi	a3,a3,-562 # ffffffffc02aa680 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02048ba:	6698                	ld	a4,8(a3)
ffffffffc02048bc:	0c878793          	addi	a5,a5,200
ffffffffc02048c0:	06f71b63          	bne	a4,a5,ffffffffc0204936 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02048c4:	629c                	ld	a5,0(a3)
ffffffffc02048c6:	04f71863          	bne	a4,a5,ffffffffc0204916 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc02048ca:	00003517          	auipc	a0,0x3
ffffffffc02048ce:	99650513          	addi	a0,a0,-1642 # ffffffffc0207260 <default_pmm_manager+0xbc0>
ffffffffc02048d2:	8c3fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02048d6:	60a2                	ld	ra,8(sp)
ffffffffc02048d8:	4501                	li	a0,0
ffffffffc02048da:	0141                	addi	sp,sp,16
ffffffffc02048dc:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02048de:	00003697          	auipc	a3,0x3
ffffffffc02048e2:	8c268693          	addi	a3,a3,-1854 # ffffffffc02071a0 <default_pmm_manager+0xb00>
ffffffffc02048e6:	00002617          	auipc	a2,0x2
ffffffffc02048ea:	a0a60613          	addi	a2,a2,-1526 # ffffffffc02062f0 <commands+0x858>
ffffffffc02048ee:	3c300593          	li	a1,963
ffffffffc02048f2:	00002517          	auipc	a0,0x2
ffffffffc02048f6:	7c650513          	addi	a0,a0,1990 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc02048fa:	b95fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc02048fe:	00003617          	auipc	a2,0x3
ffffffffc0204902:	85a60613          	addi	a2,a2,-1958 # ffffffffc0207158 <default_pmm_manager+0xab8>
ffffffffc0204906:	3ba00593          	li	a1,954
ffffffffc020490a:	00002517          	auipc	a0,0x2
ffffffffc020490e:	7ae50513          	addi	a0,a0,1966 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0204912:	b7dfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204916:	00003697          	auipc	a3,0x3
ffffffffc020491a:	91a68693          	addi	a3,a3,-1766 # ffffffffc0207230 <default_pmm_manager+0xb90>
ffffffffc020491e:	00002617          	auipc	a2,0x2
ffffffffc0204922:	9d260613          	addi	a2,a2,-1582 # ffffffffc02062f0 <commands+0x858>
ffffffffc0204926:	3c600593          	li	a1,966
ffffffffc020492a:	00002517          	auipc	a0,0x2
ffffffffc020492e:	78e50513          	addi	a0,a0,1934 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0204932:	b5dfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204936:	00003697          	auipc	a3,0x3
ffffffffc020493a:	8ca68693          	addi	a3,a3,-1846 # ffffffffc0207200 <default_pmm_manager+0xb60>
ffffffffc020493e:	00002617          	auipc	a2,0x2
ffffffffc0204942:	9b260613          	addi	a2,a2,-1614 # ffffffffc02062f0 <commands+0x858>
ffffffffc0204946:	3c500593          	li	a1,965
ffffffffc020494a:	00002517          	auipc	a0,0x2
ffffffffc020494e:	76e50513          	addi	a0,a0,1902 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0204952:	b3dfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc0204956:	00003697          	auipc	a3,0x3
ffffffffc020495a:	89a68693          	addi	a3,a3,-1894 # ffffffffc02071f0 <default_pmm_manager+0xb50>
ffffffffc020495e:	00002617          	auipc	a2,0x2
ffffffffc0204962:	99260613          	addi	a2,a2,-1646 # ffffffffc02062f0 <commands+0x858>
ffffffffc0204966:	3c400593          	li	a1,964
ffffffffc020496a:	00002517          	auipc	a0,0x2
ffffffffc020496e:	74e50513          	addi	a0,a0,1870 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0204972:	b1dfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204976 <do_execve>:
{
ffffffffc0204976:	7171                	addi	sp,sp,-176
ffffffffc0204978:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020497a:	000a6d97          	auipc	s11,0xa6
ffffffffc020497e:	d76d8d93          	addi	s11,s11,-650 # ffffffffc02aa6f0 <current>
ffffffffc0204982:	000db783          	ld	a5,0(s11)
{
ffffffffc0204986:	e54e                	sd	s3,136(sp)
ffffffffc0204988:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020498a:	0287b983          	ld	s3,40(a5)
{
ffffffffc020498e:	e94a                	sd	s2,144(sp)
ffffffffc0204990:	f4de                	sd	s7,104(sp)
ffffffffc0204992:	892a                	mv	s2,a0
ffffffffc0204994:	8bb2                	mv	s7,a2
ffffffffc0204996:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))//检查name的内存空间能否被访问
ffffffffc0204998:	862e                	mv	a2,a1
ffffffffc020499a:	4681                	li	a3,0
ffffffffc020499c:	85aa                	mv	a1,a0
ffffffffc020499e:	854e                	mv	a0,s3
{
ffffffffc02049a0:	f506                	sd	ra,168(sp)
ffffffffc02049a2:	f122                	sd	s0,160(sp)
ffffffffc02049a4:	e152                	sd	s4,128(sp)
ffffffffc02049a6:	fcd6                	sd	s5,120(sp)
ffffffffc02049a8:	f8da                	sd	s6,112(sp)
ffffffffc02049aa:	f0e2                	sd	s8,96(sp)
ffffffffc02049ac:	ece6                	sd	s9,88(sp)
ffffffffc02049ae:	e8ea                	sd	s10,80(sp)
ffffffffc02049b0:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))//检查name的内存空间能否被访问
ffffffffc02049b2:	d1aff0ef          	jal	ra,ffffffffc0203ecc <user_mem_check>
ffffffffc02049b6:	40050a63          	beqz	a0,ffffffffc0204dca <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc02049ba:	4641                	li	a2,16
ffffffffc02049bc:	4581                	li	a1,0
ffffffffc02049be:	1808                	addi	a0,sp,48
ffffffffc02049c0:	643000ef          	jal	ra,ffffffffc0205802 <memset>
    memcpy(local_name, name, len);
ffffffffc02049c4:	47bd                	li	a5,15
ffffffffc02049c6:	8626                	mv	a2,s1
ffffffffc02049c8:	1e97e263          	bltu	a5,s1,ffffffffc0204bac <do_execve+0x236>
ffffffffc02049cc:	85ca                	mv	a1,s2
ffffffffc02049ce:	1808                	addi	a0,sp,48
ffffffffc02049d0:	645000ef          	jal	ra,ffffffffc0205814 <memcpy>
    if (mm != NULL)
ffffffffc02049d4:	1e098363          	beqz	s3,ffffffffc0204bba <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc02049d8:	00002517          	auipc	a0,0x2
ffffffffc02049dc:	4a050513          	addi	a0,a0,1184 # ffffffffc0206e78 <default_pmm_manager+0x7d8>
ffffffffc02049e0:	fecfb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc02049e4:	000a6797          	auipc	a5,0xa6
ffffffffc02049e8:	cdc7b783          	ld	a5,-804(a5) # ffffffffc02aa6c0 <boot_pgdir_pa>
ffffffffc02049ec:	577d                	li	a4,-1
ffffffffc02049ee:	177e                	slli	a4,a4,0x3f
ffffffffc02049f0:	83b1                	srli	a5,a5,0xc
ffffffffc02049f2:	8fd9                	or	a5,a5,a4
ffffffffc02049f4:	18079073          	csrw	satp,a5
ffffffffc02049f8:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b78>
ffffffffc02049fc:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204a00:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204a04:	2c070463          	beqz	a4,ffffffffc0204ccc <do_execve+0x356>
        current->mm = NULL;
ffffffffc0204a08:	000db783          	ld	a5,0(s11)
ffffffffc0204a0c:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204a10:	e47fe0ef          	jal	ra,ffffffffc0203856 <mm_create>
ffffffffc0204a14:	84aa                	mv	s1,a0
ffffffffc0204a16:	1c050d63          	beqz	a0,ffffffffc0204bf0 <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204a1a:	4505                	li	a0,1
ffffffffc0204a1c:	da4fd0ef          	jal	ra,ffffffffc0201fc0 <alloc_pages>
ffffffffc0204a20:	3a050963          	beqz	a0,ffffffffc0204dd2 <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc0204a24:	000a6c97          	auipc	s9,0xa6
ffffffffc0204a28:	cb4c8c93          	addi	s9,s9,-844 # ffffffffc02aa6d8 <pages>
ffffffffc0204a2c:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204a30:	000a6c17          	auipc	s8,0xa6
ffffffffc0204a34:	ca0c0c13          	addi	s8,s8,-864 # ffffffffc02aa6d0 <npage>
    return page - pages + nbase;
ffffffffc0204a38:	00003717          	auipc	a4,0x3
ffffffffc0204a3c:	f1873703          	ld	a4,-232(a4) # ffffffffc0207950 <nbase>
ffffffffc0204a40:	40d506b3          	sub	a3,a0,a3
ffffffffc0204a44:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204a46:	5afd                	li	s5,-1
ffffffffc0204a48:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204a4c:	96ba                	add	a3,a3,a4
ffffffffc0204a4e:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204a50:	00cad713          	srli	a4,s5,0xc
ffffffffc0204a54:	ec3a                	sd	a4,24(sp)
ffffffffc0204a56:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204a58:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204a5a:	38f77063          	bgeu	a4,a5,ffffffffc0204dda <do_execve+0x464>
ffffffffc0204a5e:	000a6b17          	auipc	s6,0xa6
ffffffffc0204a62:	c8ab0b13          	addi	s6,s6,-886 # ffffffffc02aa6e8 <va_pa_offset>
ffffffffc0204a66:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204a6a:	6605                	lui	a2,0x1
ffffffffc0204a6c:	000a6597          	auipc	a1,0xa6
ffffffffc0204a70:	c5c5b583          	ld	a1,-932(a1) # ffffffffc02aa6c8 <boot_pgdir_va>
ffffffffc0204a74:	9936                	add	s2,s2,a3
ffffffffc0204a76:	854a                	mv	a0,s2
ffffffffc0204a78:	59d000ef          	jal	ra,ffffffffc0205814 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204a7c:	7782                	ld	a5,32(sp)
ffffffffc0204a7e:	4398                	lw	a4,0(a5)
ffffffffc0204a80:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204a84:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204a88:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b945f>
ffffffffc0204a8c:	14f71863          	bne	a4,a5,ffffffffc0204bdc <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a90:	7682                	ld	a3,32(sp)
ffffffffc0204a92:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204a96:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a9a:	00371793          	slli	a5,a4,0x3
ffffffffc0204a9e:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204aa0:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204aa2:	078e                	slli	a5,a5,0x3
ffffffffc0204aa4:	97ce                	add	a5,a5,s3
ffffffffc0204aa6:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204aa8:	00f9fc63          	bgeu	s3,a5,ffffffffc0204ac0 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204aac:	0009a783          	lw	a5,0(s3)
ffffffffc0204ab0:	4705                	li	a4,1
ffffffffc0204ab2:	14e78163          	beq	a5,a4,ffffffffc0204bf4 <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc0204ab6:	77a2                	ld	a5,40(sp)
ffffffffc0204ab8:	03898993          	addi	s3,s3,56
ffffffffc0204abc:	fef9e8e3          	bltu	s3,a5,ffffffffc0204aac <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204ac0:	4701                	li	a4,0
ffffffffc0204ac2:	46ad                	li	a3,11
ffffffffc0204ac4:	00100637          	lui	a2,0x100
ffffffffc0204ac8:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204acc:	8526                	mv	a0,s1
ffffffffc0204ace:	f1bfe0ef          	jal	ra,ffffffffc02039e8 <mm_map>
ffffffffc0204ad2:	8a2a                	mv	s4,a0
ffffffffc0204ad4:	1e051263          	bnez	a0,ffffffffc0204cb8 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204ad8:	6c88                	ld	a0,24(s1)
ffffffffc0204ada:	467d                	li	a2,31
ffffffffc0204adc:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204ae0:	c91fe0ef          	jal	ra,ffffffffc0203770 <pgdir_alloc_page>
ffffffffc0204ae4:	38050363          	beqz	a0,ffffffffc0204e6a <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ae8:	6c88                	ld	a0,24(s1)
ffffffffc0204aea:	467d                	li	a2,31
ffffffffc0204aec:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204af0:	c81fe0ef          	jal	ra,ffffffffc0203770 <pgdir_alloc_page>
ffffffffc0204af4:	34050b63          	beqz	a0,ffffffffc0204e4a <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204af8:	6c88                	ld	a0,24(s1)
ffffffffc0204afa:	467d                	li	a2,31
ffffffffc0204afc:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204b00:	c71fe0ef          	jal	ra,ffffffffc0203770 <pgdir_alloc_page>
ffffffffc0204b04:	32050363          	beqz	a0,ffffffffc0204e2a <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b08:	6c88                	ld	a0,24(s1)
ffffffffc0204b0a:	467d                	li	a2,31
ffffffffc0204b0c:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204b10:	c61fe0ef          	jal	ra,ffffffffc0203770 <pgdir_alloc_page>
ffffffffc0204b14:	2e050b63          	beqz	a0,ffffffffc0204e0a <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204b18:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0204b1a:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b1e:	6c94                	ld	a3,24(s1)
ffffffffc0204b20:	2785                	addiw	a5,a5,1
ffffffffc0204b22:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0204b24:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b26:	c02007b7          	lui	a5,0xc0200
ffffffffc0204b2a:	2cf6e463          	bltu	a3,a5,ffffffffc0204df2 <do_execve+0x47c>
ffffffffc0204b2e:	000b3783          	ld	a5,0(s6)
ffffffffc0204b32:	577d                	li	a4,-1
ffffffffc0204b34:	177e                	slli	a4,a4,0x3f
ffffffffc0204b36:	8e9d                	sub	a3,a3,a5
ffffffffc0204b38:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204b3c:	f654                	sd	a3,168(a2)
ffffffffc0204b3e:	8fd9                	or	a5,a5,a4
ffffffffc0204b40:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204b44:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b46:	4581                	li	a1,0
ffffffffc0204b48:	12000613          	li	a2,288
ffffffffc0204b4c:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204b4e:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b52:	4b1000ef          	jal	ra,ffffffffc0205802 <memset>
    tf->epc = elf->e_entry;
ffffffffc0204b56:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b58:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204b5c:	edf4f493          	andi	s1,s1,-289
    tf->epc = elf->e_entry;
ffffffffc0204b60:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204b62:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b64:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_exit_out_size+0xffffffff7fff4f94>
    tf->gpr.sp = USTACKTOP;
ffffffffc0204b68:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204b6a:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b6e:	4641                	li	a2,16
ffffffffc0204b70:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc0204b72:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0204b74:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204b78:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b7c:	854a                	mv	a0,s2
ffffffffc0204b7e:	485000ef          	jal	ra,ffffffffc0205802 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204b82:	463d                	li	a2,15
ffffffffc0204b84:	180c                	addi	a1,sp,48
ffffffffc0204b86:	854a                	mv	a0,s2
ffffffffc0204b88:	48d000ef          	jal	ra,ffffffffc0205814 <memcpy>
}
ffffffffc0204b8c:	70aa                	ld	ra,168(sp)
ffffffffc0204b8e:	740a                	ld	s0,160(sp)
ffffffffc0204b90:	64ea                	ld	s1,152(sp)
ffffffffc0204b92:	694a                	ld	s2,144(sp)
ffffffffc0204b94:	69aa                	ld	s3,136(sp)
ffffffffc0204b96:	7ae6                	ld	s5,120(sp)
ffffffffc0204b98:	7b46                	ld	s6,112(sp)
ffffffffc0204b9a:	7ba6                	ld	s7,104(sp)
ffffffffc0204b9c:	7c06                	ld	s8,96(sp)
ffffffffc0204b9e:	6ce6                	ld	s9,88(sp)
ffffffffc0204ba0:	6d46                	ld	s10,80(sp)
ffffffffc0204ba2:	6da6                	ld	s11,72(sp)
ffffffffc0204ba4:	8552                	mv	a0,s4
ffffffffc0204ba6:	6a0a                	ld	s4,128(sp)
ffffffffc0204ba8:	614d                	addi	sp,sp,176
ffffffffc0204baa:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204bac:	463d                	li	a2,15
ffffffffc0204bae:	85ca                	mv	a1,s2
ffffffffc0204bb0:	1808                	addi	a0,sp,48
ffffffffc0204bb2:	463000ef          	jal	ra,ffffffffc0205814 <memcpy>
    if (mm != NULL)
ffffffffc0204bb6:	e20991e3          	bnez	s3,ffffffffc02049d8 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204bba:	000db783          	ld	a5,0(s11)
ffffffffc0204bbe:	779c                	ld	a5,40(a5)
ffffffffc0204bc0:	e40788e3          	beqz	a5,ffffffffc0204a10 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204bc4:	00002617          	auipc	a2,0x2
ffffffffc0204bc8:	6bc60613          	addi	a2,a2,1724 # ffffffffc0207280 <default_pmm_manager+0xbe0>
ffffffffc0204bcc:	23f00593          	li	a1,575
ffffffffc0204bd0:	00002517          	auipc	a0,0x2
ffffffffc0204bd4:	4e850513          	addi	a0,a0,1256 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0204bd8:	8b7fb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204bdc:	8526                	mv	a0,s1
ffffffffc0204bde:	c88ff0ef          	jal	ra,ffffffffc0204066 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204be2:	8526                	mv	a0,s1
ffffffffc0204be4:	db3fe0ef          	jal	ra,ffffffffc0203996 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204be8:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc0204bea:	8552                	mv	a0,s4
ffffffffc0204bec:	94bff0ef          	jal	ra,ffffffffc0204536 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204bf0:	5a71                	li	s4,-4
ffffffffc0204bf2:	bfe5                	j	ffffffffc0204bea <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204bf4:	0289b603          	ld	a2,40(s3)
ffffffffc0204bf8:	0209b783          	ld	a5,32(s3)
ffffffffc0204bfc:	1cf66d63          	bltu	a2,a5,ffffffffc0204dd6 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204c00:	0049a783          	lw	a5,4(s3)
ffffffffc0204c04:	0017f693          	andi	a3,a5,1
ffffffffc0204c08:	c291                	beqz	a3,ffffffffc0204c0c <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204c0a:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c0c:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c10:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c12:	e779                	bnez	a4,ffffffffc0204ce0 <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204c14:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c16:	c781                	beqz	a5,ffffffffc0204c1e <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204c18:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204c1c:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204c1e:	0026f793          	andi	a5,a3,2
ffffffffc0204c22:	e3f1                	bnez	a5,ffffffffc0204ce6 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204c24:	0046f793          	andi	a5,a3,4
ffffffffc0204c28:	c399                	beqz	a5,ffffffffc0204c2e <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204c2a:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204c2e:	0109b583          	ld	a1,16(s3)
ffffffffc0204c32:	4701                	li	a4,0
ffffffffc0204c34:	8526                	mv	a0,s1
ffffffffc0204c36:	db3fe0ef          	jal	ra,ffffffffc02039e8 <mm_map>
ffffffffc0204c3a:	8a2a                	mv	s4,a0
ffffffffc0204c3c:	ed35                	bnez	a0,ffffffffc0204cb8 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204c3e:	0109bb83          	ld	s7,16(s3)
ffffffffc0204c42:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204c44:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204c48:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204c4c:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204c50:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204c52:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204c54:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204c56:	054be963          	bltu	s7,s4,ffffffffc0204ca8 <do_execve+0x332>
ffffffffc0204c5a:	aa95                	j	ffffffffc0204dce <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c5c:	6785                	lui	a5,0x1
ffffffffc0204c5e:	415b8533          	sub	a0,s7,s5
ffffffffc0204c62:	9abe                	add	s5,s5,a5
ffffffffc0204c64:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204c68:	015a7463          	bgeu	s4,s5,ffffffffc0204c70 <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204c6c:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204c70:	000cb683          	ld	a3,0(s9)
ffffffffc0204c74:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204c76:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204c7a:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c7e:	8699                	srai	a3,a3,0x6
ffffffffc0204c80:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204c82:	67e2                	ld	a5,24(sp)
ffffffffc0204c84:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c88:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c8a:	14b87863          	bgeu	a6,a1,ffffffffc0204dda <do_execve+0x464>
ffffffffc0204c8e:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204c92:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204c94:	9bb2                	add	s7,s7,a2
ffffffffc0204c96:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204c98:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204c9a:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204c9c:	379000ef          	jal	ra,ffffffffc0205814 <memcpy>
            start += size, from += size;
ffffffffc0204ca0:	6622                	ld	a2,8(sp)
ffffffffc0204ca2:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204ca4:	054bf363          	bgeu	s7,s4,ffffffffc0204cea <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204ca8:	6c88                	ld	a0,24(s1)
ffffffffc0204caa:	866a                	mv	a2,s10
ffffffffc0204cac:	85d6                	mv	a1,s5
ffffffffc0204cae:	ac3fe0ef          	jal	ra,ffffffffc0203770 <pgdir_alloc_page>
ffffffffc0204cb2:	842a                	mv	s0,a0
ffffffffc0204cb4:	f545                	bnez	a0,ffffffffc0204c5c <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204cb6:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0204cb8:	8526                	mv	a0,s1
ffffffffc0204cba:	e79fe0ef          	jal	ra,ffffffffc0203b32 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204cbe:	8526                	mv	a0,s1
ffffffffc0204cc0:	ba6ff0ef          	jal	ra,ffffffffc0204066 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204cc4:	8526                	mv	a0,s1
ffffffffc0204cc6:	cd1fe0ef          	jal	ra,ffffffffc0203996 <mm_destroy>
    return ret;
ffffffffc0204cca:	b705                	j	ffffffffc0204bea <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204ccc:	854e                	mv	a0,s3
ffffffffc0204cce:	e65fe0ef          	jal	ra,ffffffffc0203b32 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204cd2:	854e                	mv	a0,s3
ffffffffc0204cd4:	b92ff0ef          	jal	ra,ffffffffc0204066 <put_pgdir>
            mm_destroy(mm);//把进程当前占用的内存释放，之后重新分配内存 
ffffffffc0204cd8:	854e                	mv	a0,s3
ffffffffc0204cda:	cbdfe0ef          	jal	ra,ffffffffc0203996 <mm_destroy>
ffffffffc0204cde:	b32d                	j	ffffffffc0204a08 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204ce0:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204ce4:	fb95                	bnez	a5,ffffffffc0204c18 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204ce6:	4d5d                	li	s10,23
ffffffffc0204ce8:	bf35                	j	ffffffffc0204c24 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204cea:	0109b683          	ld	a3,16(s3)
ffffffffc0204cee:	0289b903          	ld	s2,40(s3)
ffffffffc0204cf2:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204cf4:	075bfd63          	bgeu	s7,s5,ffffffffc0204d6e <do_execve+0x3f8>
            if (start == end)
ffffffffc0204cf8:	db790fe3          	beq	s2,s7,ffffffffc0204ab6 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204cfc:	6785                	lui	a5,0x1
ffffffffc0204cfe:	00fb8533          	add	a0,s7,a5
ffffffffc0204d02:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204d06:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204d0a:	0b597d63          	bgeu	s2,s5,ffffffffc0204dc4 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204d0e:	000cb683          	ld	a3,0(s9)
ffffffffc0204d12:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204d14:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204d18:	40d406b3          	sub	a3,s0,a3
ffffffffc0204d1c:	8699                	srai	a3,a3,0x6
ffffffffc0204d1e:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204d20:	67e2                	ld	a5,24(sp)
ffffffffc0204d22:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d26:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d28:	0ac5f963          	bgeu	a1,a2,ffffffffc0204dda <do_execve+0x464>
ffffffffc0204d2c:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d30:	8652                	mv	a2,s4
ffffffffc0204d32:	4581                	li	a1,0
ffffffffc0204d34:	96c2                	add	a3,a3,a6
ffffffffc0204d36:	9536                	add	a0,a0,a3
ffffffffc0204d38:	2cb000ef          	jal	ra,ffffffffc0205802 <memset>
            start += size;
ffffffffc0204d3c:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204d40:	03597463          	bgeu	s2,s5,ffffffffc0204d68 <do_execve+0x3f2>
ffffffffc0204d44:	d6e909e3          	beq	s2,a4,ffffffffc0204ab6 <do_execve+0x140>
ffffffffc0204d48:	00002697          	auipc	a3,0x2
ffffffffc0204d4c:	56068693          	addi	a3,a3,1376 # ffffffffc02072a8 <default_pmm_manager+0xc08>
ffffffffc0204d50:	00001617          	auipc	a2,0x1
ffffffffc0204d54:	5a060613          	addi	a2,a2,1440 # ffffffffc02062f0 <commands+0x858>
ffffffffc0204d58:	2a800593          	li	a1,680
ffffffffc0204d5c:	00002517          	auipc	a0,0x2
ffffffffc0204d60:	35c50513          	addi	a0,a0,860 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0204d64:	f2afb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204d68:	ff5710e3          	bne	a4,s5,ffffffffc0204d48 <do_execve+0x3d2>
ffffffffc0204d6c:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204d6e:	d52bf4e3          	bgeu	s7,s2,ffffffffc0204ab6 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204d72:	6c88                	ld	a0,24(s1)
ffffffffc0204d74:	866a                	mv	a2,s10
ffffffffc0204d76:	85d6                	mv	a1,s5
ffffffffc0204d78:	9f9fe0ef          	jal	ra,ffffffffc0203770 <pgdir_alloc_page>
ffffffffc0204d7c:	842a                	mv	s0,a0
ffffffffc0204d7e:	dd05                	beqz	a0,ffffffffc0204cb6 <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204d80:	6785                	lui	a5,0x1
ffffffffc0204d82:	415b8533          	sub	a0,s7,s5
ffffffffc0204d86:	9abe                	add	s5,s5,a5
ffffffffc0204d88:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204d8c:	01597463          	bgeu	s2,s5,ffffffffc0204d94 <do_execve+0x41e>
                size -= la - end;
ffffffffc0204d90:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204d94:	000cb683          	ld	a3,0(s9)
ffffffffc0204d98:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204d9a:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204d9e:	40d406b3          	sub	a3,s0,a3
ffffffffc0204da2:	8699                	srai	a3,a3,0x6
ffffffffc0204da4:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204da6:	67e2                	ld	a5,24(sp)
ffffffffc0204da8:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204dac:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204dae:	02b87663          	bgeu	a6,a1,ffffffffc0204dda <do_execve+0x464>
ffffffffc0204db2:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204db6:	4581                	li	a1,0
            start += size;
ffffffffc0204db8:	9bb2                	add	s7,s7,a2
ffffffffc0204dba:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204dbc:	9536                	add	a0,a0,a3
ffffffffc0204dbe:	245000ef          	jal	ra,ffffffffc0205802 <memset>
ffffffffc0204dc2:	b775                	j	ffffffffc0204d6e <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204dc4:	417a8a33          	sub	s4,s5,s7
ffffffffc0204dc8:	b799                	j	ffffffffc0204d0e <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204dca:	5a75                	li	s4,-3
ffffffffc0204dcc:	b3c1                	j	ffffffffc0204b8c <do_execve+0x216>
        while (start < end)
ffffffffc0204dce:	86de                	mv	a3,s7
ffffffffc0204dd0:	bf39                	j	ffffffffc0204cee <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204dd2:	5a71                	li	s4,-4
ffffffffc0204dd4:	bdc5                	j	ffffffffc0204cc4 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204dd6:	5a61                	li	s4,-8
ffffffffc0204dd8:	b5c5                	j	ffffffffc0204cb8 <do_execve+0x342>
ffffffffc0204dda:	00001617          	auipc	a2,0x1
ffffffffc0204dde:	46e60613          	addi	a2,a2,1134 # ffffffffc0206248 <commands+0x7b0>
ffffffffc0204de2:	07100593          	li	a1,113
ffffffffc0204de6:	00001517          	auipc	a0,0x1
ffffffffc0204dea:	48a50513          	addi	a0,a0,1162 # ffffffffc0206270 <commands+0x7d8>
ffffffffc0204dee:	ea0fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204df2:	00002617          	auipc	a2,0x2
ffffffffc0204df6:	95660613          	addi	a2,a2,-1706 # ffffffffc0206748 <default_pmm_manager+0xa8>
ffffffffc0204dfa:	2c700593          	li	a1,711
ffffffffc0204dfe:	00002517          	auipc	a0,0x2
ffffffffc0204e02:	2ba50513          	addi	a0,a0,698 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0204e06:	e88fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e0a:	00002697          	auipc	a3,0x2
ffffffffc0204e0e:	5b668693          	addi	a3,a3,1462 # ffffffffc02073c0 <default_pmm_manager+0xd20>
ffffffffc0204e12:	00001617          	auipc	a2,0x1
ffffffffc0204e16:	4de60613          	addi	a2,a2,1246 # ffffffffc02062f0 <commands+0x858>
ffffffffc0204e1a:	2c200593          	li	a1,706
ffffffffc0204e1e:	00002517          	auipc	a0,0x2
ffffffffc0204e22:	29a50513          	addi	a0,a0,666 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0204e26:	e68fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e2a:	00002697          	auipc	a3,0x2
ffffffffc0204e2e:	54e68693          	addi	a3,a3,1358 # ffffffffc0207378 <default_pmm_manager+0xcd8>
ffffffffc0204e32:	00001617          	auipc	a2,0x1
ffffffffc0204e36:	4be60613          	addi	a2,a2,1214 # ffffffffc02062f0 <commands+0x858>
ffffffffc0204e3a:	2c100593          	li	a1,705
ffffffffc0204e3e:	00002517          	auipc	a0,0x2
ffffffffc0204e42:	27a50513          	addi	a0,a0,634 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0204e46:	e48fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e4a:	00002697          	auipc	a3,0x2
ffffffffc0204e4e:	4e668693          	addi	a3,a3,1254 # ffffffffc0207330 <default_pmm_manager+0xc90>
ffffffffc0204e52:	00001617          	auipc	a2,0x1
ffffffffc0204e56:	49e60613          	addi	a2,a2,1182 # ffffffffc02062f0 <commands+0x858>
ffffffffc0204e5a:	2c000593          	li	a1,704
ffffffffc0204e5e:	00002517          	auipc	a0,0x2
ffffffffc0204e62:	25a50513          	addi	a0,a0,602 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0204e66:	e28fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204e6a:	00002697          	auipc	a3,0x2
ffffffffc0204e6e:	47e68693          	addi	a3,a3,1150 # ffffffffc02072e8 <default_pmm_manager+0xc48>
ffffffffc0204e72:	00001617          	auipc	a2,0x1
ffffffffc0204e76:	47e60613          	addi	a2,a2,1150 # ffffffffc02062f0 <commands+0x858>
ffffffffc0204e7a:	2bf00593          	li	a1,703
ffffffffc0204e7e:	00002517          	auipc	a0,0x2
ffffffffc0204e82:	23a50513          	addi	a0,a0,570 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0204e86:	e08fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204e8a <do_yield>:
    current->need_resched = 1;
ffffffffc0204e8a:	000a6797          	auipc	a5,0xa6
ffffffffc0204e8e:	8667b783          	ld	a5,-1946(a5) # ffffffffc02aa6f0 <current>
ffffffffc0204e92:	4705                	li	a4,1
ffffffffc0204e94:	ef98                	sd	a4,24(a5)
}
ffffffffc0204e96:	4501                	li	a0,0
ffffffffc0204e98:	8082                	ret

ffffffffc0204e9a <do_wait>:
{
ffffffffc0204e9a:	1101                	addi	sp,sp,-32
ffffffffc0204e9c:	e822                	sd	s0,16(sp)
ffffffffc0204e9e:	e426                	sd	s1,8(sp)
ffffffffc0204ea0:	ec06                	sd	ra,24(sp)
ffffffffc0204ea2:	842e                	mv	s0,a1
ffffffffc0204ea4:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204ea6:	c999                	beqz	a1,ffffffffc0204ebc <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204ea8:	000a6797          	auipc	a5,0xa6
ffffffffc0204eac:	8487b783          	ld	a5,-1976(a5) # ffffffffc02aa6f0 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204eb0:	7788                	ld	a0,40(a5)
ffffffffc0204eb2:	4685                	li	a3,1
ffffffffc0204eb4:	4611                	li	a2,4
ffffffffc0204eb6:	816ff0ef          	jal	ra,ffffffffc0203ecc <user_mem_check>
ffffffffc0204eba:	c909                	beqz	a0,ffffffffc0204ecc <do_wait+0x32>
ffffffffc0204ebc:	85a2                	mv	a1,s0
}
ffffffffc0204ebe:	6442                	ld	s0,16(sp)
ffffffffc0204ec0:	60e2                	ld	ra,24(sp)
ffffffffc0204ec2:	8526                	mv	a0,s1
ffffffffc0204ec4:	64a2                	ld	s1,8(sp)
ffffffffc0204ec6:	6105                	addi	sp,sp,32
ffffffffc0204ec8:	fb8ff06f          	j	ffffffffc0204680 <do_wait.part.0>
ffffffffc0204ecc:	60e2                	ld	ra,24(sp)
ffffffffc0204ece:	6442                	ld	s0,16(sp)
ffffffffc0204ed0:	64a2                	ld	s1,8(sp)
ffffffffc0204ed2:	5575                	li	a0,-3
ffffffffc0204ed4:	6105                	addi	sp,sp,32
ffffffffc0204ed6:	8082                	ret

ffffffffc0204ed8 <do_kill>:
{
ffffffffc0204ed8:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204eda:	6789                	lui	a5,0x2
{
ffffffffc0204edc:	e406                	sd	ra,8(sp)
ffffffffc0204ede:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204ee0:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204ee4:	17f9                	addi	a5,a5,-2
ffffffffc0204ee6:	02e7e963          	bltu	a5,a4,ffffffffc0204f18 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204eea:	842a                	mv	s0,a0
ffffffffc0204eec:	45a9                	li	a1,10
ffffffffc0204eee:	2501                	sext.w	a0,a0
ffffffffc0204ef0:	46c000ef          	jal	ra,ffffffffc020535c <hash32>
ffffffffc0204ef4:	02051793          	slli	a5,a0,0x20
ffffffffc0204ef8:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204efc:	000a1797          	auipc	a5,0xa1
ffffffffc0204f00:	78478793          	addi	a5,a5,1924 # ffffffffc02a6680 <hash_list>
ffffffffc0204f04:	953e                	add	a0,a0,a5
ffffffffc0204f06:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204f08:	a029                	j	ffffffffc0204f12 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204f0a:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204f0e:	00870b63          	beq	a4,s0,ffffffffc0204f24 <do_kill+0x4c>
ffffffffc0204f12:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204f14:	fef51be3          	bne	a0,a5,ffffffffc0204f0a <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204f18:	5475                	li	s0,-3
}
ffffffffc0204f1a:	60a2                	ld	ra,8(sp)
ffffffffc0204f1c:	8522                	mv	a0,s0
ffffffffc0204f1e:	6402                	ld	s0,0(sp)
ffffffffc0204f20:	0141                	addi	sp,sp,16
ffffffffc0204f22:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204f24:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204f28:	00177693          	andi	a3,a4,1
ffffffffc0204f2c:	e295                	bnez	a3,ffffffffc0204f50 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f2e:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204f30:	00176713          	ori	a4,a4,1
ffffffffc0204f34:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204f38:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f3a:	fe06d0e3          	bgez	a3,ffffffffc0204f1a <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204f3e:	f2878513          	addi	a0,a5,-216
ffffffffc0204f42:	22e000ef          	jal	ra,ffffffffc0205170 <wakeup_proc>
}
ffffffffc0204f46:	60a2                	ld	ra,8(sp)
ffffffffc0204f48:	8522                	mv	a0,s0
ffffffffc0204f4a:	6402                	ld	s0,0(sp)
ffffffffc0204f4c:	0141                	addi	sp,sp,16
ffffffffc0204f4e:	8082                	ret
        return -E_KILLED;
ffffffffc0204f50:	545d                	li	s0,-9
ffffffffc0204f52:	b7e1                	j	ffffffffc0204f1a <do_kill+0x42>

ffffffffc0204f54 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204f54:	1101                	addi	sp,sp,-32
ffffffffc0204f56:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204f58:	000a5797          	auipc	a5,0xa5
ffffffffc0204f5c:	72878793          	addi	a5,a5,1832 # ffffffffc02aa680 <proc_list>
ffffffffc0204f60:	ec06                	sd	ra,24(sp)
ffffffffc0204f62:	e822                	sd	s0,16(sp)
ffffffffc0204f64:	e04a                	sd	s2,0(sp)
ffffffffc0204f66:	000a1497          	auipc	s1,0xa1
ffffffffc0204f6a:	71a48493          	addi	s1,s1,1818 # ffffffffc02a6680 <hash_list>
ffffffffc0204f6e:	e79c                	sd	a5,8(a5)
ffffffffc0204f70:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204f72:	000a5717          	auipc	a4,0xa5
ffffffffc0204f76:	70e70713          	addi	a4,a4,1806 # ffffffffc02aa680 <proc_list>
ffffffffc0204f7a:	87a6                	mv	a5,s1
ffffffffc0204f7c:	e79c                	sd	a5,8(a5)
ffffffffc0204f7e:	e39c                	sd	a5,0(a5)
ffffffffc0204f80:	07c1                	addi	a5,a5,16
ffffffffc0204f82:	fef71de3          	bne	a4,a5,ffffffffc0204f7c <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204f86:	fe3fe0ef          	jal	ra,ffffffffc0203f68 <alloc_proc>
ffffffffc0204f8a:	000a5917          	auipc	s2,0xa5
ffffffffc0204f8e:	76e90913          	addi	s2,s2,1902 # ffffffffc02aa6f8 <idleproc>
ffffffffc0204f92:	00a93023          	sd	a0,0(s2)
ffffffffc0204f96:	0e050f63          	beqz	a0,ffffffffc0205094 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204f9a:	4789                	li	a5,2
ffffffffc0204f9c:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204f9e:	00003797          	auipc	a5,0x3
ffffffffc0204fa2:	06278793          	addi	a5,a5,98 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fa6:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204faa:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204fac:	4785                	li	a5,1
ffffffffc0204fae:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fb0:	4641                	li	a2,16
ffffffffc0204fb2:	4581                	li	a1,0
ffffffffc0204fb4:	8522                	mv	a0,s0
ffffffffc0204fb6:	04d000ef          	jal	ra,ffffffffc0205802 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204fba:	463d                	li	a2,15
ffffffffc0204fbc:	00002597          	auipc	a1,0x2
ffffffffc0204fc0:	46458593          	addi	a1,a1,1124 # ffffffffc0207420 <default_pmm_manager+0xd80>
ffffffffc0204fc4:	8522                	mv	a0,s0
ffffffffc0204fc6:	04f000ef          	jal	ra,ffffffffc0205814 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204fca:	000a5717          	auipc	a4,0xa5
ffffffffc0204fce:	73e70713          	addi	a4,a4,1854 # ffffffffc02aa708 <nr_process>
ffffffffc0204fd2:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204fd4:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);//创建一个内核进程执行init_main()函数
ffffffffc0204fd8:	4601                	li	a2,0
    nr_process++;
ffffffffc0204fda:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);//创建一个内核进程执行init_main()函数
ffffffffc0204fdc:	4581                	li	a1,0
ffffffffc0204fde:	00000517          	auipc	a0,0x0
ffffffffc0204fe2:	87450513          	addi	a0,a0,-1932 # ffffffffc0204852 <init_main>
    nr_process++;
ffffffffc0204fe6:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204fe8:	000a5797          	auipc	a5,0xa5
ffffffffc0204fec:	70d7b423          	sd	a3,1800(a5) # ffffffffc02aa6f0 <current>
    int pid = kernel_thread(init_main, NULL, 0);//创建一个内核进程执行init_main()函数
ffffffffc0204ff0:	cf6ff0ef          	jal	ra,ffffffffc02044e6 <kernel_thread>
ffffffffc0204ff4:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204ff6:	08a05363          	blez	a0,ffffffffc020507c <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204ffa:	6789                	lui	a5,0x2
ffffffffc0204ffc:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205000:	17f9                	addi	a5,a5,-2
ffffffffc0205002:	2501                	sext.w	a0,a0
ffffffffc0205004:	02e7e363          	bltu	a5,a4,ffffffffc020502a <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205008:	45a9                	li	a1,10
ffffffffc020500a:	352000ef          	jal	ra,ffffffffc020535c <hash32>
ffffffffc020500e:	02051793          	slli	a5,a0,0x20
ffffffffc0205012:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0205016:	96a6                	add	a3,a3,s1
ffffffffc0205018:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc020501a:	a029                	j	ffffffffc0205024 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc020501c:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c7c>
ffffffffc0205020:	04870b63          	beq	a4,s0,ffffffffc0205076 <proc_init+0x122>
    return listelm->next;
ffffffffc0205024:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0205026:	fef69be3          	bne	a3,a5,ffffffffc020501c <proc_init+0xc8>
    return NULL;
ffffffffc020502a:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020502c:	0b478493          	addi	s1,a5,180
ffffffffc0205030:	4641                	li	a2,16
ffffffffc0205032:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205034:	000a5417          	auipc	s0,0xa5
ffffffffc0205038:	6cc40413          	addi	s0,s0,1740 # ffffffffc02aa700 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020503c:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc020503e:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205040:	7c2000ef          	jal	ra,ffffffffc0205802 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205044:	463d                	li	a2,15
ffffffffc0205046:	00002597          	auipc	a1,0x2
ffffffffc020504a:	40258593          	addi	a1,a1,1026 # ffffffffc0207448 <default_pmm_manager+0xda8>
ffffffffc020504e:	8526                	mv	a0,s1
ffffffffc0205050:	7c4000ef          	jal	ra,ffffffffc0205814 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205054:	00093783          	ld	a5,0(s2)
ffffffffc0205058:	cbb5                	beqz	a5,ffffffffc02050cc <proc_init+0x178>
ffffffffc020505a:	43dc                	lw	a5,4(a5)
ffffffffc020505c:	eba5                	bnez	a5,ffffffffc02050cc <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020505e:	601c                	ld	a5,0(s0)
ffffffffc0205060:	c7b1                	beqz	a5,ffffffffc02050ac <proc_init+0x158>
ffffffffc0205062:	43d8                	lw	a4,4(a5)
ffffffffc0205064:	4785                	li	a5,1
ffffffffc0205066:	04f71363          	bne	a4,a5,ffffffffc02050ac <proc_init+0x158>
}
ffffffffc020506a:	60e2                	ld	ra,24(sp)
ffffffffc020506c:	6442                	ld	s0,16(sp)
ffffffffc020506e:	64a2                	ld	s1,8(sp)
ffffffffc0205070:	6902                	ld	s2,0(sp)
ffffffffc0205072:	6105                	addi	sp,sp,32
ffffffffc0205074:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205076:	f2878793          	addi	a5,a5,-216
ffffffffc020507a:	bf4d                	j	ffffffffc020502c <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc020507c:	00002617          	auipc	a2,0x2
ffffffffc0205080:	3ac60613          	addi	a2,a2,940 # ffffffffc0207428 <default_pmm_manager+0xd88>
ffffffffc0205084:	3e900593          	li	a1,1001
ffffffffc0205088:	00002517          	auipc	a0,0x2
ffffffffc020508c:	03050513          	addi	a0,a0,48 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc0205090:	bfefb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205094:	00002617          	auipc	a2,0x2
ffffffffc0205098:	37460613          	addi	a2,a2,884 # ffffffffc0207408 <default_pmm_manager+0xd68>
ffffffffc020509c:	3da00593          	li	a1,986
ffffffffc02050a0:	00002517          	auipc	a0,0x2
ffffffffc02050a4:	01850513          	addi	a0,a0,24 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc02050a8:	be6fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02050ac:	00002697          	auipc	a3,0x2
ffffffffc02050b0:	3cc68693          	addi	a3,a3,972 # ffffffffc0207478 <default_pmm_manager+0xdd8>
ffffffffc02050b4:	00001617          	auipc	a2,0x1
ffffffffc02050b8:	23c60613          	addi	a2,a2,572 # ffffffffc02062f0 <commands+0x858>
ffffffffc02050bc:	3f000593          	li	a1,1008
ffffffffc02050c0:	00002517          	auipc	a0,0x2
ffffffffc02050c4:	ff850513          	addi	a0,a0,-8 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc02050c8:	bc6fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02050cc:	00002697          	auipc	a3,0x2
ffffffffc02050d0:	38468693          	addi	a3,a3,900 # ffffffffc0207450 <default_pmm_manager+0xdb0>
ffffffffc02050d4:	00001617          	auipc	a2,0x1
ffffffffc02050d8:	21c60613          	addi	a2,a2,540 # ffffffffc02062f0 <commands+0x858>
ffffffffc02050dc:	3ef00593          	li	a1,1007
ffffffffc02050e0:	00002517          	auipc	a0,0x2
ffffffffc02050e4:	fd850513          	addi	a0,a0,-40 # ffffffffc02070b8 <default_pmm_manager+0xa18>
ffffffffc02050e8:	ba6fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02050ec <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc02050ec:	1141                	addi	sp,sp,-16
ffffffffc02050ee:	e022                	sd	s0,0(sp)
ffffffffc02050f0:	e406                	sd	ra,8(sp)
ffffffffc02050f2:	000a5417          	auipc	s0,0xa5
ffffffffc02050f6:	5fe40413          	addi	s0,s0,1534 # ffffffffc02aa6f0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02050fa:	6018                	ld	a4,0(s0)
ffffffffc02050fc:	6f1c                	ld	a5,24(a4)
ffffffffc02050fe:	dffd                	beqz	a5,ffffffffc02050fc <cpu_idle+0x10>
        {
            schedule();
ffffffffc0205100:	0f0000ef          	jal	ra,ffffffffc02051f0 <schedule>
ffffffffc0205104:	bfdd                	j	ffffffffc02050fa <cpu_idle+0xe>

ffffffffc0205106 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205106:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc020510a:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc020510e:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205110:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205112:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205116:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc020511a:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc020511e:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0205122:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205126:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc020512a:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc020512e:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0205132:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205136:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc020513a:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc020513e:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0205142:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205144:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205146:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc020514a:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc020514e:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0205152:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205156:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc020515a:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc020515e:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0205162:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205166:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc020516a:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc020516e:	8082                	ret

ffffffffc0205170 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205170:	4118                	lw	a4,0(a0)
{
ffffffffc0205172:	1101                	addi	sp,sp,-32
ffffffffc0205174:	ec06                	sd	ra,24(sp)
ffffffffc0205176:	e822                	sd	s0,16(sp)
ffffffffc0205178:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020517a:	478d                	li	a5,3
ffffffffc020517c:	04f70b63          	beq	a4,a5,ffffffffc02051d2 <wakeup_proc+0x62>
ffffffffc0205180:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205182:	100027f3          	csrr	a5,sstatus
ffffffffc0205186:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205188:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020518a:	ef9d                	bnez	a5,ffffffffc02051c8 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc020518c:	4789                	li	a5,2
ffffffffc020518e:	02f70163          	beq	a4,a5,ffffffffc02051b0 <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc0205192:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205194:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc0205198:	e491                	bnez	s1,ffffffffc02051a4 <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020519a:	60e2                	ld	ra,24(sp)
ffffffffc020519c:	6442                	ld	s0,16(sp)
ffffffffc020519e:	64a2                	ld	s1,8(sp)
ffffffffc02051a0:	6105                	addi	sp,sp,32
ffffffffc02051a2:	8082                	ret
ffffffffc02051a4:	6442                	ld	s0,16(sp)
ffffffffc02051a6:	60e2                	ld	ra,24(sp)
ffffffffc02051a8:	64a2                	ld	s1,8(sp)
ffffffffc02051aa:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02051ac:	803fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc02051b0:	00002617          	auipc	a2,0x2
ffffffffc02051b4:	32860613          	addi	a2,a2,808 # ffffffffc02074d8 <default_pmm_manager+0xe38>
ffffffffc02051b8:	45d1                	li	a1,20
ffffffffc02051ba:	00002517          	auipc	a0,0x2
ffffffffc02051be:	30650513          	addi	a0,a0,774 # ffffffffc02074c0 <default_pmm_manager+0xe20>
ffffffffc02051c2:	b34fb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc02051c6:	bfc9                	j	ffffffffc0205198 <wakeup_proc+0x28>
        intr_disable();
ffffffffc02051c8:	fecfb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc02051cc:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc02051ce:	4485                	li	s1,1
ffffffffc02051d0:	bf75                	j	ffffffffc020518c <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051d2:	00002697          	auipc	a3,0x2
ffffffffc02051d6:	2ce68693          	addi	a3,a3,718 # ffffffffc02074a0 <default_pmm_manager+0xe00>
ffffffffc02051da:	00001617          	auipc	a2,0x1
ffffffffc02051de:	11660613          	addi	a2,a2,278 # ffffffffc02062f0 <commands+0x858>
ffffffffc02051e2:	45a5                	li	a1,9
ffffffffc02051e4:	00002517          	auipc	a0,0x2
ffffffffc02051e8:	2dc50513          	addi	a0,a0,732 # ffffffffc02074c0 <default_pmm_manager+0xe20>
ffffffffc02051ec:	aa2fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02051f0 <schedule>:

void schedule(void)
{
ffffffffc02051f0:	1141                	addi	sp,sp,-16
ffffffffc02051f2:	e406                	sd	ra,8(sp)
ffffffffc02051f4:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02051f6:	100027f3          	csrr	a5,sstatus
ffffffffc02051fa:	8b89                	andi	a5,a5,2
ffffffffc02051fc:	4401                	li	s0,0
ffffffffc02051fe:	efbd                	bnez	a5,ffffffffc020527c <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205200:	000a5897          	auipc	a7,0xa5
ffffffffc0205204:	4f08b883          	ld	a7,1264(a7) # ffffffffc02aa6f0 <current>
ffffffffc0205208:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020520c:	000a5517          	auipc	a0,0xa5
ffffffffc0205210:	4ec53503          	ld	a0,1260(a0) # ffffffffc02aa6f8 <idleproc>
ffffffffc0205214:	04a88e63          	beq	a7,a0,ffffffffc0205270 <schedule+0x80>
ffffffffc0205218:	0c888693          	addi	a3,a7,200
ffffffffc020521c:	000a5617          	auipc	a2,0xa5
ffffffffc0205220:	46460613          	addi	a2,a2,1124 # ffffffffc02aa680 <proc_list>
        le = last;
ffffffffc0205224:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0205226:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc0205228:	4809                	li	a6,2
ffffffffc020522a:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc020522c:	00c78863          	beq	a5,a2,ffffffffc020523c <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc0205230:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0205234:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205238:	03070163          	beq	a4,a6,ffffffffc020525a <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc020523c:	fef697e3          	bne	a3,a5,ffffffffc020522a <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205240:	ed89                	bnez	a1,ffffffffc020525a <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc0205242:	451c                	lw	a5,8(a0)
ffffffffc0205244:	2785                	addiw	a5,a5,1
ffffffffc0205246:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc0205248:	00a88463          	beq	a7,a0,ffffffffc0205250 <schedule+0x60>
        {
            proc_run(next);
ffffffffc020524c:	e91fe0ef          	jal	ra,ffffffffc02040dc <proc_run>
    if (flag)
ffffffffc0205250:	e819                	bnez	s0,ffffffffc0205266 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205252:	60a2                	ld	ra,8(sp)
ffffffffc0205254:	6402                	ld	s0,0(sp)
ffffffffc0205256:	0141                	addi	sp,sp,16
ffffffffc0205258:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020525a:	4198                	lw	a4,0(a1)
ffffffffc020525c:	4789                	li	a5,2
ffffffffc020525e:	fef712e3          	bne	a4,a5,ffffffffc0205242 <schedule+0x52>
ffffffffc0205262:	852e                	mv	a0,a1
ffffffffc0205264:	bff9                	j	ffffffffc0205242 <schedule+0x52>
}
ffffffffc0205266:	6402                	ld	s0,0(sp)
ffffffffc0205268:	60a2                	ld	ra,8(sp)
ffffffffc020526a:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020526c:	f42fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205270:	000a5617          	auipc	a2,0xa5
ffffffffc0205274:	41060613          	addi	a2,a2,1040 # ffffffffc02aa680 <proc_list>
ffffffffc0205278:	86b2                	mv	a3,a2
ffffffffc020527a:	b76d                	j	ffffffffc0205224 <schedule+0x34>
        intr_disable();
ffffffffc020527c:	f38fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0205280:	4405                	li	s0,1
ffffffffc0205282:	bfbd                	j	ffffffffc0205200 <schedule+0x10>

ffffffffc0205284 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205284:	000a5797          	auipc	a5,0xa5
ffffffffc0205288:	46c7b783          	ld	a5,1132(a5) # ffffffffc02aa6f0 <current>
}
ffffffffc020528c:	43c8                	lw	a0,4(a5)
ffffffffc020528e:	8082                	ret

ffffffffc0205290 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205290:	4501                	li	a0,0
ffffffffc0205292:	8082                	ret

ffffffffc0205294 <sys_putc>:
    cputchar(c);
ffffffffc0205294:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205296:	1141                	addi	sp,sp,-16
ffffffffc0205298:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc020529a:	f31fa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc020529e:	60a2                	ld	ra,8(sp)
ffffffffc02052a0:	4501                	li	a0,0
ffffffffc02052a2:	0141                	addi	sp,sp,16
ffffffffc02052a4:	8082                	ret

ffffffffc02052a6 <sys_kill>:
    return do_kill(pid);
ffffffffc02052a6:	4108                	lw	a0,0(a0)
ffffffffc02052a8:	c31ff06f          	j	ffffffffc0204ed8 <do_kill>

ffffffffc02052ac <sys_yield>:
    return do_yield();
ffffffffc02052ac:	bdfff06f          	j	ffffffffc0204e8a <do_yield>

ffffffffc02052b0 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02052b0:	6d14                	ld	a3,24(a0)
ffffffffc02052b2:	6910                	ld	a2,16(a0)
ffffffffc02052b4:	650c                	ld	a1,8(a0)
ffffffffc02052b6:	6108                	ld	a0,0(a0)
ffffffffc02052b8:	ebeff06f          	j	ffffffffc0204976 <do_execve>

ffffffffc02052bc <sys_wait>:
    return do_wait(pid, store);
ffffffffc02052bc:	650c                	ld	a1,8(a0)
ffffffffc02052be:	4108                	lw	a0,0(a0)
ffffffffc02052c0:	bdbff06f          	j	ffffffffc0204e9a <do_wait>

ffffffffc02052c4 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02052c4:	000a5797          	auipc	a5,0xa5
ffffffffc02052c8:	42c7b783          	ld	a5,1068(a5) # ffffffffc02aa6f0 <current>
ffffffffc02052cc:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02052ce:	4501                	li	a0,0
ffffffffc02052d0:	6a0c                	ld	a1,16(a2)
ffffffffc02052d2:	e6ffe06f          	j	ffffffffc0204140 <do_fork>

ffffffffc02052d6 <sys_exit>:
    return do_exit(error_code);
ffffffffc02052d6:	4108                	lw	a0,0(a0)
ffffffffc02052d8:	a5eff06f          	j	ffffffffc0204536 <do_exit>

ffffffffc02052dc <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc02052dc:	715d                	addi	sp,sp,-80
ffffffffc02052de:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc02052e0:	000a5497          	auipc	s1,0xa5
ffffffffc02052e4:	41048493          	addi	s1,s1,1040 # ffffffffc02aa6f0 <current>
ffffffffc02052e8:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02052ea:	e0a2                	sd	s0,64(sp)
ffffffffc02052ec:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02052ee:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02052f0:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02052f2:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc02052f4:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02052f8:	0327ee63          	bltu	a5,s2,ffffffffc0205334 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc02052fc:	00391713          	slli	a4,s2,0x3
ffffffffc0205300:	00002797          	auipc	a5,0x2
ffffffffc0205304:	24078793          	addi	a5,a5,576 # ffffffffc0207540 <syscalls>
ffffffffc0205308:	97ba                	add	a5,a5,a4
ffffffffc020530a:	639c                	ld	a5,0(a5)
ffffffffc020530c:	c785                	beqz	a5,ffffffffc0205334 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc020530e:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0205310:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205312:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205314:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205316:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205318:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc020531a:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc020531c:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc020531e:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0205320:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205322:	0028                	addi	a0,sp,8
ffffffffc0205324:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205326:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205328:	e828                	sd	a0,80(s0)
}
ffffffffc020532a:	6406                	ld	s0,64(sp)
ffffffffc020532c:	74e2                	ld	s1,56(sp)
ffffffffc020532e:	7942                	ld	s2,48(sp)
ffffffffc0205330:	6161                	addi	sp,sp,80
ffffffffc0205332:	8082                	ret
    print_trapframe(tf);
ffffffffc0205334:	8522                	mv	a0,s0
ffffffffc0205336:	86ffb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc020533a:	609c                	ld	a5,0(s1)
ffffffffc020533c:	86ca                	mv	a3,s2
ffffffffc020533e:	00002617          	auipc	a2,0x2
ffffffffc0205342:	1ba60613          	addi	a2,a2,442 # ffffffffc02074f8 <default_pmm_manager+0xe58>
ffffffffc0205346:	43d8                	lw	a4,4(a5)
ffffffffc0205348:	06200593          	li	a1,98
ffffffffc020534c:	0b478793          	addi	a5,a5,180
ffffffffc0205350:	00002517          	auipc	a0,0x2
ffffffffc0205354:	1d850513          	addi	a0,a0,472 # ffffffffc0207528 <default_pmm_manager+0xe88>
ffffffffc0205358:	936fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020535c <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc020535c:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205360:	2785                	addiw	a5,a5,1
ffffffffc0205362:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205366:	02000793          	li	a5,32
ffffffffc020536a:	9f8d                	subw	a5,a5,a1
}
ffffffffc020536c:	00f5553b          	srlw	a0,a0,a5
ffffffffc0205370:	8082                	ret

ffffffffc0205372 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205372:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205376:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0205378:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020537c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020537e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205382:	f022                	sd	s0,32(sp)
ffffffffc0205384:	ec26                	sd	s1,24(sp)
ffffffffc0205386:	e84a                	sd	s2,16(sp)
ffffffffc0205388:	f406                	sd	ra,40(sp)
ffffffffc020538a:	e44e                	sd	s3,8(sp)
ffffffffc020538c:	84aa                	mv	s1,a0
ffffffffc020538e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205390:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0205394:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0205396:	03067e63          	bgeu	a2,a6,ffffffffc02053d2 <printnum+0x60>
ffffffffc020539a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020539c:	00805763          	blez	s0,ffffffffc02053aa <printnum+0x38>
ffffffffc02053a0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02053a2:	85ca                	mv	a1,s2
ffffffffc02053a4:	854e                	mv	a0,s3
ffffffffc02053a6:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02053a8:	fc65                	bnez	s0,ffffffffc02053a0 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053aa:	1a02                	slli	s4,s4,0x20
ffffffffc02053ac:	00002797          	auipc	a5,0x2
ffffffffc02053b0:	29478793          	addi	a5,a5,660 # ffffffffc0207640 <syscalls+0x100>
ffffffffc02053b4:	020a5a13          	srli	s4,s4,0x20
ffffffffc02053b8:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02053ba:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053bc:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02053c0:	70a2                	ld	ra,40(sp)
ffffffffc02053c2:	69a2                	ld	s3,8(sp)
ffffffffc02053c4:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053c6:	85ca                	mv	a1,s2
ffffffffc02053c8:	87a6                	mv	a5,s1
}
ffffffffc02053ca:	6942                	ld	s2,16(sp)
ffffffffc02053cc:	64e2                	ld	s1,24(sp)
ffffffffc02053ce:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053d0:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02053d2:	03065633          	divu	a2,a2,a6
ffffffffc02053d6:	8722                	mv	a4,s0
ffffffffc02053d8:	f9bff0ef          	jal	ra,ffffffffc0205372 <printnum>
ffffffffc02053dc:	b7f9                	j	ffffffffc02053aa <printnum+0x38>

ffffffffc02053de <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02053de:	7119                	addi	sp,sp,-128
ffffffffc02053e0:	f4a6                	sd	s1,104(sp)
ffffffffc02053e2:	f0ca                	sd	s2,96(sp)
ffffffffc02053e4:	ecce                	sd	s3,88(sp)
ffffffffc02053e6:	e8d2                	sd	s4,80(sp)
ffffffffc02053e8:	e4d6                	sd	s5,72(sp)
ffffffffc02053ea:	e0da                	sd	s6,64(sp)
ffffffffc02053ec:	fc5e                	sd	s7,56(sp)
ffffffffc02053ee:	f06a                	sd	s10,32(sp)
ffffffffc02053f0:	fc86                	sd	ra,120(sp)
ffffffffc02053f2:	f8a2                	sd	s0,112(sp)
ffffffffc02053f4:	f862                	sd	s8,48(sp)
ffffffffc02053f6:	f466                	sd	s9,40(sp)
ffffffffc02053f8:	ec6e                	sd	s11,24(sp)
ffffffffc02053fa:	892a                	mv	s2,a0
ffffffffc02053fc:	84ae                	mv	s1,a1
ffffffffc02053fe:	8d32                	mv	s10,a2
ffffffffc0205400:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205402:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205406:	5b7d                	li	s6,-1
ffffffffc0205408:	00002a97          	auipc	s5,0x2
ffffffffc020540c:	264a8a93          	addi	s5,s5,612 # ffffffffc020766c <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205410:	00002b97          	auipc	s7,0x2
ffffffffc0205414:	478b8b93          	addi	s7,s7,1144 # ffffffffc0207888 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205418:	000d4503          	lbu	a0,0(s10)
ffffffffc020541c:	001d0413          	addi	s0,s10,1
ffffffffc0205420:	01350a63          	beq	a0,s3,ffffffffc0205434 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0205424:	c121                	beqz	a0,ffffffffc0205464 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0205426:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205428:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020542a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020542c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0205430:	ff351ae3          	bne	a0,s3,ffffffffc0205424 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205434:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205438:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020543c:	4c81                	li	s9,0
ffffffffc020543e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0205440:	5c7d                	li	s8,-1
ffffffffc0205442:	5dfd                	li	s11,-1
ffffffffc0205444:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0205448:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020544a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020544e:	0ff5f593          	zext.b	a1,a1
ffffffffc0205452:	00140d13          	addi	s10,s0,1
ffffffffc0205456:	04b56263          	bltu	a0,a1,ffffffffc020549a <vprintfmt+0xbc>
ffffffffc020545a:	058a                	slli	a1,a1,0x2
ffffffffc020545c:	95d6                	add	a1,a1,s5
ffffffffc020545e:	4194                	lw	a3,0(a1)
ffffffffc0205460:	96d6                	add	a3,a3,s5
ffffffffc0205462:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205464:	70e6                	ld	ra,120(sp)
ffffffffc0205466:	7446                	ld	s0,112(sp)
ffffffffc0205468:	74a6                	ld	s1,104(sp)
ffffffffc020546a:	7906                	ld	s2,96(sp)
ffffffffc020546c:	69e6                	ld	s3,88(sp)
ffffffffc020546e:	6a46                	ld	s4,80(sp)
ffffffffc0205470:	6aa6                	ld	s5,72(sp)
ffffffffc0205472:	6b06                	ld	s6,64(sp)
ffffffffc0205474:	7be2                	ld	s7,56(sp)
ffffffffc0205476:	7c42                	ld	s8,48(sp)
ffffffffc0205478:	7ca2                	ld	s9,40(sp)
ffffffffc020547a:	7d02                	ld	s10,32(sp)
ffffffffc020547c:	6de2                	ld	s11,24(sp)
ffffffffc020547e:	6109                	addi	sp,sp,128
ffffffffc0205480:	8082                	ret
            padc = '0';
ffffffffc0205482:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0205484:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205488:	846a                	mv	s0,s10
ffffffffc020548a:	00140d13          	addi	s10,s0,1
ffffffffc020548e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205492:	0ff5f593          	zext.b	a1,a1
ffffffffc0205496:	fcb572e3          	bgeu	a0,a1,ffffffffc020545a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020549a:	85a6                	mv	a1,s1
ffffffffc020549c:	02500513          	li	a0,37
ffffffffc02054a0:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02054a2:	fff44783          	lbu	a5,-1(s0)
ffffffffc02054a6:	8d22                	mv	s10,s0
ffffffffc02054a8:	f73788e3          	beq	a5,s3,ffffffffc0205418 <vprintfmt+0x3a>
ffffffffc02054ac:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02054b0:	1d7d                	addi	s10,s10,-1
ffffffffc02054b2:	ff379de3          	bne	a5,s3,ffffffffc02054ac <vprintfmt+0xce>
ffffffffc02054b6:	b78d                	j	ffffffffc0205418 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02054b8:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02054bc:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054c0:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02054c2:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02054c6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02054ca:	02d86463          	bltu	a6,a3,ffffffffc02054f2 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02054ce:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02054d2:	002c169b          	slliw	a3,s8,0x2
ffffffffc02054d6:	0186873b          	addw	a4,a3,s8
ffffffffc02054da:	0017171b          	slliw	a4,a4,0x1
ffffffffc02054de:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02054e0:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02054e4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02054e6:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02054ea:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02054ee:	fed870e3          	bgeu	a6,a3,ffffffffc02054ce <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02054f2:	f40ddce3          	bgez	s11,ffffffffc020544a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02054f6:	8de2                	mv	s11,s8
ffffffffc02054f8:	5c7d                	li	s8,-1
ffffffffc02054fa:	bf81                	j	ffffffffc020544a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02054fc:	fffdc693          	not	a3,s11
ffffffffc0205500:	96fd                	srai	a3,a3,0x3f
ffffffffc0205502:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205506:	00144603          	lbu	a2,1(s0)
ffffffffc020550a:	2d81                	sext.w	s11,s11
ffffffffc020550c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020550e:	bf35                	j	ffffffffc020544a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205510:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205514:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0205518:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020551a:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020551c:	bfd9                	j	ffffffffc02054f2 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020551e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205520:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205524:	01174463          	blt	a4,a7,ffffffffc020552c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0205528:	1a088e63          	beqz	a7,ffffffffc02056e4 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020552c:	000a3603          	ld	a2,0(s4)
ffffffffc0205530:	46c1                	li	a3,16
ffffffffc0205532:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205534:	2781                	sext.w	a5,a5
ffffffffc0205536:	876e                	mv	a4,s11
ffffffffc0205538:	85a6                	mv	a1,s1
ffffffffc020553a:	854a                	mv	a0,s2
ffffffffc020553c:	e37ff0ef          	jal	ra,ffffffffc0205372 <printnum>
            break;
ffffffffc0205540:	bde1                	j	ffffffffc0205418 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0205542:	000a2503          	lw	a0,0(s4)
ffffffffc0205546:	85a6                	mv	a1,s1
ffffffffc0205548:	0a21                	addi	s4,s4,8
ffffffffc020554a:	9902                	jalr	s2
            break;
ffffffffc020554c:	b5f1                	j	ffffffffc0205418 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020554e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205550:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205554:	01174463          	blt	a4,a7,ffffffffc020555c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205558:	18088163          	beqz	a7,ffffffffc02056da <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020555c:	000a3603          	ld	a2,0(s4)
ffffffffc0205560:	46a9                	li	a3,10
ffffffffc0205562:	8a2e                	mv	s4,a1
ffffffffc0205564:	bfc1                	j	ffffffffc0205534 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205566:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020556a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020556c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020556e:	bdf1                	j	ffffffffc020544a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0205570:	85a6                	mv	a1,s1
ffffffffc0205572:	02500513          	li	a0,37
ffffffffc0205576:	9902                	jalr	s2
            break;
ffffffffc0205578:	b545                	j	ffffffffc0205418 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020557a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020557e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205580:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205582:	b5e1                	j	ffffffffc020544a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0205584:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205586:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020558a:	01174463          	blt	a4,a7,ffffffffc0205592 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020558e:	14088163          	beqz	a7,ffffffffc02056d0 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0205592:	000a3603          	ld	a2,0(s4)
ffffffffc0205596:	46a1                	li	a3,8
ffffffffc0205598:	8a2e                	mv	s4,a1
ffffffffc020559a:	bf69                	j	ffffffffc0205534 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020559c:	03000513          	li	a0,48
ffffffffc02055a0:	85a6                	mv	a1,s1
ffffffffc02055a2:	e03e                	sd	a5,0(sp)
ffffffffc02055a4:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02055a6:	85a6                	mv	a1,s1
ffffffffc02055a8:	07800513          	li	a0,120
ffffffffc02055ac:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055ae:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02055b0:	6782                	ld	a5,0(sp)
ffffffffc02055b2:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055b4:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02055b8:	bfb5                	j	ffffffffc0205534 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02055ba:	000a3403          	ld	s0,0(s4)
ffffffffc02055be:	008a0713          	addi	a4,s4,8
ffffffffc02055c2:	e03a                	sd	a4,0(sp)
ffffffffc02055c4:	14040263          	beqz	s0,ffffffffc0205708 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02055c8:	0fb05763          	blez	s11,ffffffffc02056b6 <vprintfmt+0x2d8>
ffffffffc02055cc:	02d00693          	li	a3,45
ffffffffc02055d0:	0cd79163          	bne	a5,a3,ffffffffc0205692 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055d4:	00044783          	lbu	a5,0(s0)
ffffffffc02055d8:	0007851b          	sext.w	a0,a5
ffffffffc02055dc:	cf85                	beqz	a5,ffffffffc0205614 <vprintfmt+0x236>
ffffffffc02055de:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02055e2:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055e6:	000c4563          	bltz	s8,ffffffffc02055f0 <vprintfmt+0x212>
ffffffffc02055ea:	3c7d                	addiw	s8,s8,-1
ffffffffc02055ec:	036c0263          	beq	s8,s6,ffffffffc0205610 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02055f0:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02055f2:	0e0c8e63          	beqz	s9,ffffffffc02056ee <vprintfmt+0x310>
ffffffffc02055f6:	3781                	addiw	a5,a5,-32
ffffffffc02055f8:	0ef47b63          	bgeu	s0,a5,ffffffffc02056ee <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02055fc:	03f00513          	li	a0,63
ffffffffc0205600:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205602:	000a4783          	lbu	a5,0(s4)
ffffffffc0205606:	3dfd                	addiw	s11,s11,-1
ffffffffc0205608:	0a05                	addi	s4,s4,1
ffffffffc020560a:	0007851b          	sext.w	a0,a5
ffffffffc020560e:	ffe1                	bnez	a5,ffffffffc02055e6 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205610:	01b05963          	blez	s11,ffffffffc0205622 <vprintfmt+0x244>
ffffffffc0205614:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205616:	85a6                	mv	a1,s1
ffffffffc0205618:	02000513          	li	a0,32
ffffffffc020561c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020561e:	fe0d9be3          	bnez	s11,ffffffffc0205614 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205622:	6a02                	ld	s4,0(sp)
ffffffffc0205624:	bbd5                	j	ffffffffc0205418 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205626:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205628:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020562c:	01174463          	blt	a4,a7,ffffffffc0205634 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205630:	08088d63          	beqz	a7,ffffffffc02056ca <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205634:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205638:	0a044d63          	bltz	s0,ffffffffc02056f2 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020563c:	8622                	mv	a2,s0
ffffffffc020563e:	8a66                	mv	s4,s9
ffffffffc0205640:	46a9                	li	a3,10
ffffffffc0205642:	bdcd                	j	ffffffffc0205534 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205644:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205648:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc020564a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020564c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0205650:	8fb5                	xor	a5,a5,a3
ffffffffc0205652:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205656:	02d74163          	blt	a4,a3,ffffffffc0205678 <vprintfmt+0x29a>
ffffffffc020565a:	00369793          	slli	a5,a3,0x3
ffffffffc020565e:	97de                	add	a5,a5,s7
ffffffffc0205660:	639c                	ld	a5,0(a5)
ffffffffc0205662:	cb99                	beqz	a5,ffffffffc0205678 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205664:	86be                	mv	a3,a5
ffffffffc0205666:	00000617          	auipc	a2,0x0
ffffffffc020566a:	1f260613          	addi	a2,a2,498 # ffffffffc0205858 <etext+0x2c>
ffffffffc020566e:	85a6                	mv	a1,s1
ffffffffc0205670:	854a                	mv	a0,s2
ffffffffc0205672:	0ce000ef          	jal	ra,ffffffffc0205740 <printfmt>
ffffffffc0205676:	b34d                	j	ffffffffc0205418 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205678:	00002617          	auipc	a2,0x2
ffffffffc020567c:	fe860613          	addi	a2,a2,-24 # ffffffffc0207660 <syscalls+0x120>
ffffffffc0205680:	85a6                	mv	a1,s1
ffffffffc0205682:	854a                	mv	a0,s2
ffffffffc0205684:	0bc000ef          	jal	ra,ffffffffc0205740 <printfmt>
ffffffffc0205688:	bb41                	j	ffffffffc0205418 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020568a:	00002417          	auipc	s0,0x2
ffffffffc020568e:	fce40413          	addi	s0,s0,-50 # ffffffffc0207658 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205692:	85e2                	mv	a1,s8
ffffffffc0205694:	8522                	mv	a0,s0
ffffffffc0205696:	e43e                	sd	a5,8(sp)
ffffffffc0205698:	0e2000ef          	jal	ra,ffffffffc020577a <strnlen>
ffffffffc020569c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02056a0:	01b05b63          	blez	s11,ffffffffc02056b6 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02056a4:	67a2                	ld	a5,8(sp)
ffffffffc02056a6:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056aa:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02056ac:	85a6                	mv	a1,s1
ffffffffc02056ae:	8552                	mv	a0,s4
ffffffffc02056b0:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056b2:	fe0d9ce3          	bnez	s11,ffffffffc02056aa <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056b6:	00044783          	lbu	a5,0(s0)
ffffffffc02056ba:	00140a13          	addi	s4,s0,1
ffffffffc02056be:	0007851b          	sext.w	a0,a5
ffffffffc02056c2:	d3a5                	beqz	a5,ffffffffc0205622 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02056c4:	05e00413          	li	s0,94
ffffffffc02056c8:	bf39                	j	ffffffffc02055e6 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02056ca:	000a2403          	lw	s0,0(s4)
ffffffffc02056ce:	b7ad                	j	ffffffffc0205638 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02056d0:	000a6603          	lwu	a2,0(s4)
ffffffffc02056d4:	46a1                	li	a3,8
ffffffffc02056d6:	8a2e                	mv	s4,a1
ffffffffc02056d8:	bdb1                	j	ffffffffc0205534 <vprintfmt+0x156>
ffffffffc02056da:	000a6603          	lwu	a2,0(s4)
ffffffffc02056de:	46a9                	li	a3,10
ffffffffc02056e0:	8a2e                	mv	s4,a1
ffffffffc02056e2:	bd89                	j	ffffffffc0205534 <vprintfmt+0x156>
ffffffffc02056e4:	000a6603          	lwu	a2,0(s4)
ffffffffc02056e8:	46c1                	li	a3,16
ffffffffc02056ea:	8a2e                	mv	s4,a1
ffffffffc02056ec:	b5a1                	j	ffffffffc0205534 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02056ee:	9902                	jalr	s2
ffffffffc02056f0:	bf09                	j	ffffffffc0205602 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02056f2:	85a6                	mv	a1,s1
ffffffffc02056f4:	02d00513          	li	a0,45
ffffffffc02056f8:	e03e                	sd	a5,0(sp)
ffffffffc02056fa:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02056fc:	6782                	ld	a5,0(sp)
ffffffffc02056fe:	8a66                	mv	s4,s9
ffffffffc0205700:	40800633          	neg	a2,s0
ffffffffc0205704:	46a9                	li	a3,10
ffffffffc0205706:	b53d                	j	ffffffffc0205534 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205708:	03b05163          	blez	s11,ffffffffc020572a <vprintfmt+0x34c>
ffffffffc020570c:	02d00693          	li	a3,45
ffffffffc0205710:	f6d79de3          	bne	a5,a3,ffffffffc020568a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205714:	00002417          	auipc	s0,0x2
ffffffffc0205718:	f4440413          	addi	s0,s0,-188 # ffffffffc0207658 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020571c:	02800793          	li	a5,40
ffffffffc0205720:	02800513          	li	a0,40
ffffffffc0205724:	00140a13          	addi	s4,s0,1
ffffffffc0205728:	bd6d                	j	ffffffffc02055e2 <vprintfmt+0x204>
ffffffffc020572a:	00002a17          	auipc	s4,0x2
ffffffffc020572e:	f2fa0a13          	addi	s4,s4,-209 # ffffffffc0207659 <syscalls+0x119>
ffffffffc0205732:	02800513          	li	a0,40
ffffffffc0205736:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020573a:	05e00413          	li	s0,94
ffffffffc020573e:	b565                	j	ffffffffc02055e6 <vprintfmt+0x208>

ffffffffc0205740 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205740:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205742:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205746:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205748:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020574a:	ec06                	sd	ra,24(sp)
ffffffffc020574c:	f83a                	sd	a4,48(sp)
ffffffffc020574e:	fc3e                	sd	a5,56(sp)
ffffffffc0205750:	e0c2                	sd	a6,64(sp)
ffffffffc0205752:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205754:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205756:	c89ff0ef          	jal	ra,ffffffffc02053de <vprintfmt>
}
ffffffffc020575a:	60e2                	ld	ra,24(sp)
ffffffffc020575c:	6161                	addi	sp,sp,80
ffffffffc020575e:	8082                	ret

ffffffffc0205760 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205760:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205764:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205766:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205768:	cb81                	beqz	a5,ffffffffc0205778 <strlen+0x18>
        cnt ++;
ffffffffc020576a:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020576c:	00a707b3          	add	a5,a4,a0
ffffffffc0205770:	0007c783          	lbu	a5,0(a5)
ffffffffc0205774:	fbfd                	bnez	a5,ffffffffc020576a <strlen+0xa>
ffffffffc0205776:	8082                	ret
    }
    return cnt;
}
ffffffffc0205778:	8082                	ret

ffffffffc020577a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020577a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020577c:	e589                	bnez	a1,ffffffffc0205786 <strnlen+0xc>
ffffffffc020577e:	a811                	j	ffffffffc0205792 <strnlen+0x18>
        cnt ++;
ffffffffc0205780:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205782:	00f58863          	beq	a1,a5,ffffffffc0205792 <strnlen+0x18>
ffffffffc0205786:	00f50733          	add	a4,a0,a5
ffffffffc020578a:	00074703          	lbu	a4,0(a4)
ffffffffc020578e:	fb6d                	bnez	a4,ffffffffc0205780 <strnlen+0x6>
ffffffffc0205790:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205792:	852e                	mv	a0,a1
ffffffffc0205794:	8082                	ret

ffffffffc0205796 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205796:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205798:	0005c703          	lbu	a4,0(a1)
ffffffffc020579c:	0785                	addi	a5,a5,1
ffffffffc020579e:	0585                	addi	a1,a1,1
ffffffffc02057a0:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02057a4:	fb75                	bnez	a4,ffffffffc0205798 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02057a6:	8082                	ret

ffffffffc02057a8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057a8:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057ac:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057b0:	cb89                	beqz	a5,ffffffffc02057c2 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02057b2:	0505                	addi	a0,a0,1
ffffffffc02057b4:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057b6:	fee789e3          	beq	a5,a4,ffffffffc02057a8 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057ba:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02057be:	9d19                	subw	a0,a0,a4
ffffffffc02057c0:	8082                	ret
ffffffffc02057c2:	4501                	li	a0,0
ffffffffc02057c4:	bfed                	j	ffffffffc02057be <strcmp+0x16>

ffffffffc02057c6 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057c6:	c20d                	beqz	a2,ffffffffc02057e8 <strncmp+0x22>
ffffffffc02057c8:	962e                	add	a2,a2,a1
ffffffffc02057ca:	a031                	j	ffffffffc02057d6 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02057cc:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057ce:	00e79a63          	bne	a5,a4,ffffffffc02057e2 <strncmp+0x1c>
ffffffffc02057d2:	00b60b63          	beq	a2,a1,ffffffffc02057e8 <strncmp+0x22>
ffffffffc02057d6:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02057da:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057dc:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02057e0:	f7f5                	bnez	a5,ffffffffc02057cc <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057e2:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02057e6:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057e8:	4501                	li	a0,0
ffffffffc02057ea:	8082                	ret

ffffffffc02057ec <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02057ec:	00054783          	lbu	a5,0(a0)
ffffffffc02057f0:	c799                	beqz	a5,ffffffffc02057fe <strchr+0x12>
        if (*s == c) {
ffffffffc02057f2:	00f58763          	beq	a1,a5,ffffffffc0205800 <strchr+0x14>
    while (*s != '\0') {
ffffffffc02057f6:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02057fa:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02057fc:	fbfd                	bnez	a5,ffffffffc02057f2 <strchr+0x6>
    }
    return NULL;
ffffffffc02057fe:	4501                	li	a0,0
}
ffffffffc0205800:	8082                	ret

ffffffffc0205802 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205802:	ca01                	beqz	a2,ffffffffc0205812 <memset+0x10>
ffffffffc0205804:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205806:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205808:	0785                	addi	a5,a5,1
ffffffffc020580a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020580e:	fec79de3          	bne	a5,a2,ffffffffc0205808 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205812:	8082                	ret

ffffffffc0205814 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205814:	ca19                	beqz	a2,ffffffffc020582a <memcpy+0x16>
ffffffffc0205816:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205818:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc020581a:	0005c703          	lbu	a4,0(a1)
ffffffffc020581e:	0585                	addi	a1,a1,1
ffffffffc0205820:	0785                	addi	a5,a5,1
ffffffffc0205822:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205826:	fec59ae3          	bne	a1,a2,ffffffffc020581a <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc020582a:	8082                	ret
