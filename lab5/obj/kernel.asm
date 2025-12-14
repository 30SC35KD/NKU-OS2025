
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
ffffffffc020004e:	25650513          	addi	a0,a0,598 # ffffffffc02a62a0 <buf>
ffffffffc0200052:	000aa617          	auipc	a2,0xaa
ffffffffc0200056:	6f260613          	addi	a2,a2,1778 # ffffffffc02aa744 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	027050ef          	jal	ra,ffffffffc0205888 <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00006597          	auipc	a1,0x6
ffffffffc0200072:	84a58593          	addi	a1,a1,-1974 # ffffffffc02058b8 <etext+0x6>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	86250513          	addi	a0,a0,-1950 # ffffffffc02058d8 <etext+0x26>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	095020ef          	jal	ra,ffffffffc020291a <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	39d030ef          	jal	ra,ffffffffc0203c2e <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	745040ef          	jal	ra,ffffffffc0204fda <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	0d0050ef          	jal	ra,ffffffffc0205172 <cpu_idle>

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
ffffffffc02000bc:	00006517          	auipc	a0,0x6
ffffffffc02000c0:	82450513          	addi	a0,a0,-2012 # ffffffffc02058e0 <etext+0x2e>
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
ffffffffc02000d6:	1ceb8b93          	addi	s7,s7,462 # ffffffffc02a62a0 <buf>
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
ffffffffc0200132:	17250513          	addi	a0,a0,370 # ffffffffc02a62a0 <buf>
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
ffffffffc0200188:	2dc050ef          	jal	ra,ffffffffc0205464 <vprintfmt>
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
ffffffffc02001be:	2a6050ef          	jal	ra,ffffffffc0205464 <vprintfmt>
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
ffffffffc0200222:	6ca50513          	addi	a0,a0,1738 # ffffffffc02058e8 <etext+0x36>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	6d450513          	addi	a0,a0,1748 # ffffffffc0205908 <etext+0x56>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	67258593          	addi	a1,a1,1650 # ffffffffc02058b2 <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	6e050513          	addi	a0,a0,1760 # ffffffffc0205928 <etext+0x76>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000a6597          	auipc	a1,0xa6
ffffffffc0200258:	04c58593          	addi	a1,a1,76 # ffffffffc02a62a0 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	6ec50513          	addi	a0,a0,1772 # ffffffffc0205948 <etext+0x96>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000aa597          	auipc	a1,0xaa
ffffffffc020026c:	4dc58593          	addi	a1,a1,1244 # ffffffffc02aa744 <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	6f850513          	addi	a0,a0,1784 # ffffffffc0205968 <etext+0xb6>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000ab597          	auipc	a1,0xab
ffffffffc0200280:	8c758593          	addi	a1,a1,-1849 # ffffffffc02aab43 <end+0x3ff>
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
ffffffffc02002a2:	6ea50513          	addi	a0,a0,1770 # ffffffffc0205988 <etext+0xd6>
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
ffffffffc02002b0:	70c60613          	addi	a2,a2,1804 # ffffffffc02059b8 <etext+0x106>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	71850513          	addi	a0,a0,1816 # ffffffffc02059d0 <etext+0x11e>
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
ffffffffc02002cc:	72060613          	addi	a2,a2,1824 # ffffffffc02059e8 <etext+0x136>
ffffffffc02002d0:	00005597          	auipc	a1,0x5
ffffffffc02002d4:	73858593          	addi	a1,a1,1848 # ffffffffc0205a08 <etext+0x156>
ffffffffc02002d8:	00005517          	auipc	a0,0x5
ffffffffc02002dc:	73850513          	addi	a0,a0,1848 # ffffffffc0205a10 <etext+0x15e>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00005617          	auipc	a2,0x5
ffffffffc02002ea:	73a60613          	addi	a2,a2,1850 # ffffffffc0205a20 <etext+0x16e>
ffffffffc02002ee:	00005597          	auipc	a1,0x5
ffffffffc02002f2:	75a58593          	addi	a1,a1,1882 # ffffffffc0205a48 <etext+0x196>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	71a50513          	addi	a0,a0,1818 # ffffffffc0205a10 <etext+0x15e>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00005617          	auipc	a2,0x5
ffffffffc0200306:	75660613          	addi	a2,a2,1878 # ffffffffc0205a58 <etext+0x1a6>
ffffffffc020030a:	00005597          	auipc	a1,0x5
ffffffffc020030e:	76e58593          	addi	a1,a1,1902 # ffffffffc0205a78 <etext+0x1c6>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	6fe50513          	addi	a0,a0,1790 # ffffffffc0205a10 <etext+0x15e>
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
ffffffffc0200350:	73c50513          	addi	a0,a0,1852 # ffffffffc0205a88 <etext+0x1d6>
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
ffffffffc0200372:	74250513          	addi	a0,a0,1858 # ffffffffc0205ab0 <etext+0x1fe>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00005c17          	auipc	s8,0x5
ffffffffc0200388:	79cc0c13          	addi	s8,s8,1948 # ffffffffc0205b20 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00005917          	auipc	s2,0x5
ffffffffc0200390:	74c90913          	addi	s2,s2,1868 # ffffffffc0205ad8 <etext+0x226>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00005497          	auipc	s1,0x5
ffffffffc0200398:	74c48493          	addi	s1,s1,1868 # ffffffffc0205ae0 <etext+0x22e>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00005b17          	auipc	s6,0x5
ffffffffc02003a2:	74ab0b13          	addi	s6,s6,1866 # ffffffffc0205ae8 <etext+0x236>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	662a0a13          	addi	s4,s4,1634 # ffffffffc0205a08 <etext+0x156>
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
ffffffffc02003cc:	758d0d13          	addi	s10,s10,1880 # ffffffffc0205b20 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	458050ef          	jal	ra,ffffffffc020582e <strcmp>
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
ffffffffc02003ea:	444050ef          	jal	ra,ffffffffc020582e <strcmp>
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
ffffffffc0200428:	44a050ef          	jal	ra,ffffffffc0205872 <strchr>
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
ffffffffc0200466:	40c050ef          	jal	ra,ffffffffc0205872 <strchr>
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
ffffffffc0200484:	68850513          	addi	a0,a0,1672 # ffffffffc0205b08 <etext+0x256>
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
ffffffffc0200492:	23a30313          	addi	t1,t1,570 # ffffffffc02aa6c8 <is_panic>
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
ffffffffc02004c0:	6ac50513          	addi	a0,a0,1708 # ffffffffc0205b68 <commands+0x48>
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
ffffffffc02004d6:	7de50513          	addi	a0,a0,2014 # ffffffffc0206cb0 <default_pmm_manager+0x4f8>
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
ffffffffc020050a:	68250513          	addi	a0,a0,1666 # ffffffffc0205b88 <commands+0x68>
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
ffffffffc020052a:	78a50513          	addi	a0,a0,1930 # ffffffffc0206cb0 <default_pmm_manager+0x4f8>
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
ffffffffc0200544:	18f73c23          	sd	a5,408(a4) # ffffffffc02aa6d8 <timebase>
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
ffffffffc0200564:	64850513          	addi	a0,a0,1608 # ffffffffc0205ba8 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000aa797          	auipc	a5,0xaa
ffffffffc020056c:	1607b423          	sd	zero,360(a5) # ffffffffc02aa6d0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000aa797          	auipc	a5,0xaa
ffffffffc020057a:	1627b783          	ld	a5,354(a5) # ffffffffc02aa6d8 <timebase>
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
ffffffffc0200604:	5c850513          	addi	a0,a0,1480 # ffffffffc0205bc8 <commands+0xa8>
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
ffffffffc0200632:	5aa50513          	addi	a0,a0,1450 # ffffffffc0205bd8 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	5a450513          	addi	a0,a0,1444 # ffffffffc0205be8 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	5ac50513          	addi	a0,a0,1452 # ffffffffc0205c00 <commands+0xe0>
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
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe357a9>
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
ffffffffc0200712:	54290913          	addi	s2,s2,1346 # ffffffffc0205c50 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	52c48493          	addi	s1,s1,1324 # ffffffffc0205c48 <commands+0x128>
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
ffffffffc0200774:	55850513          	addi	a0,a0,1368 # ffffffffc0205cc8 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	58450513          	addi	a0,a0,1412 # ffffffffc0205d00 <commands+0x1e0>
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
ffffffffc02007c0:	46450513          	addi	a0,a0,1124 # ffffffffc0205c20 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	01c050ef          	jal	ra,ffffffffc02057e6 <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	074050ef          	jal	ra,ffffffffc020584c <strncmp>
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
ffffffffc020086e:	7c1040ef          	jal	ra,ffffffffc020582e <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	3d650513          	addi	a0,a0,982 # ffffffffc0205c58 <commands+0x138>
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
ffffffffc0200954:	32850513          	addi	a0,a0,808 # ffffffffc0205c78 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	32e50513          	addi	a0,a0,814 # ffffffffc0205c90 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	33c50513          	addi	a0,a0,828 # ffffffffc0205cb0 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	38050513          	addi	a0,a0,896 # ffffffffc0205d00 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000aa797          	auipc	a5,0xaa
ffffffffc020098c:	d487bc23          	sd	s0,-680(a5) # ffffffffc02aa6e0 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000aa797          	auipc	a5,0xaa
ffffffffc0200994:	d567bc23          	sd	s6,-680(a5) # ffffffffc02aa6e8 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000aa517          	auipc	a0,0xaa
ffffffffc020099e:	d4653503          	ld	a0,-698(a0) # ffffffffc02aa6e0 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000aa517          	auipc	a0,0xaa
ffffffffc02009a8:	d4453503          	ld	a0,-700(a0) # ffffffffc02aa6e8 <memory_size>
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
ffffffffc02009c4:	68878793          	addi	a5,a5,1672 # ffffffffc0201048 <__alltraps>
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
ffffffffc02009e2:	33a50513          	addi	a0,a0,826 # ffffffffc0205d18 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	34250513          	addi	a0,a0,834 # ffffffffc0205d30 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	34c50513          	addi	a0,a0,844 # ffffffffc0205d48 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	35650513          	addi	a0,a0,854 # ffffffffc0205d60 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	36050513          	addi	a0,a0,864 # ffffffffc0205d78 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	36a50513          	addi	a0,a0,874 # ffffffffc0205d90 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	37450513          	addi	a0,a0,884 # ffffffffc0205da8 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	37e50513          	addi	a0,a0,894 # ffffffffc0205dc0 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	38850513          	addi	a0,a0,904 # ffffffffc0205dd8 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	39250513          	addi	a0,a0,914 # ffffffffc0205df0 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	39c50513          	addi	a0,a0,924 # ffffffffc0205e08 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	3a650513          	addi	a0,a0,934 # ffffffffc0205e20 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	3b050513          	addi	a0,a0,944 # ffffffffc0205e38 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	3ba50513          	addi	a0,a0,954 # ffffffffc0205e50 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	3c450513          	addi	a0,a0,964 # ffffffffc0205e68 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	3ce50513          	addi	a0,a0,974 # ffffffffc0205e80 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	3d850513          	addi	a0,a0,984 # ffffffffc0205e98 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	3e250513          	addi	a0,a0,994 # ffffffffc0205eb0 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	3ec50513          	addi	a0,a0,1004 # ffffffffc0205ec8 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	3f650513          	addi	a0,a0,1014 # ffffffffc0205ee0 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	40050513          	addi	a0,a0,1024 # ffffffffc0205ef8 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	40a50513          	addi	a0,a0,1034 # ffffffffc0205f10 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	41450513          	addi	a0,a0,1044 # ffffffffc0205f28 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	41e50513          	addi	a0,a0,1054 # ffffffffc0205f40 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	42850513          	addi	a0,a0,1064 # ffffffffc0205f58 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	43250513          	addi	a0,a0,1074 # ffffffffc0205f70 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	43c50513          	addi	a0,a0,1084 # ffffffffc0205f88 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	44650513          	addi	a0,a0,1094 # ffffffffc0205fa0 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	45050513          	addi	a0,a0,1104 # ffffffffc0205fb8 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	45a50513          	addi	a0,a0,1114 # ffffffffc0205fd0 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	46450513          	addi	a0,a0,1124 # ffffffffc0205fe8 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	46a50513          	addi	a0,a0,1130 # ffffffffc0206000 <commands+0x4e0>
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
ffffffffc0200bb0:	46c50513          	addi	a0,a0,1132 # ffffffffc0206018 <commands+0x4f8>
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
ffffffffc0200bc8:	46c50513          	addi	a0,a0,1132 # ffffffffc0206030 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	47450513          	addi	a0,a0,1140 # ffffffffc0206048 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	47c50513          	addi	a0,a0,1148 # ffffffffc0206060 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	47850513          	addi	a0,a0,1144 # ffffffffc0206070 <commands+0x550>
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
ffffffffc0200c18:	51470713          	addi	a4,a4,1300 # ffffffffc0206128 <commands+0x608>
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
ffffffffc0200c2a:	4c250513          	addi	a0,a0,1218 # ffffffffc02060e8 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00005517          	auipc	a0,0x5
ffffffffc0200c36:	49650513          	addi	a0,a0,1174 # ffffffffc02060c8 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	44a50513          	addi	a0,a0,1098 # ffffffffc0206088 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00005517          	auipc	a0,0x5
ffffffffc0200c4e:	45e50513          	addi	a0,a0,1118 # ffffffffc02060a8 <commands+0x588>
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
ffffffffc0200c62:	a7278793          	addi	a5,a5,-1422 # ffffffffc02aa6d0 <ticks>
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
ffffffffc0200c7c:	ab07b783          	ld	a5,-1360(a5) # ffffffffc02aa728 <current>
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
ffffffffc0200c90:	47c50513          	addi	a0,a0,1148 # ffffffffc0206108 <commands+0x5e8>
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
ffffffffc0200c9e:	715d                	addi	sp,sp,-80
ffffffffc0200ca0:	e0a2                	sd	s0,64(sp)
ffffffffc0200ca2:	e486                	sd	ra,72(sp)
ffffffffc0200ca4:	fc26                	sd	s1,56(sp)
ffffffffc0200ca6:	f84a                	sd	s2,48(sp)
ffffffffc0200ca8:	f44e                	sd	s3,40(sp)
ffffffffc0200caa:	f052                	sd	s4,32(sp)
ffffffffc0200cac:	ec56                	sd	s5,24(sp)
ffffffffc0200cae:	e85a                	sd	s6,16(sp)
ffffffffc0200cb0:	e45e                	sd	s7,8(sp)
ffffffffc0200cb2:	473d                	li	a4,15
ffffffffc0200cb4:	842a                	mv	s0,a0
ffffffffc0200cb6:	1ef76663          	bltu	a4,a5,ffffffffc0200ea2 <exception_handler+0x208>
ffffffffc0200cba:	00005717          	auipc	a4,0x5
ffffffffc0200cbe:	6fe70713          	addi	a4,a4,1790 # ffffffffc02063b8 <commands+0x898>
ffffffffc0200cc2:	078a                	slli	a5,a5,0x2
ffffffffc0200cc4:	97ba                	add	a5,a5,a4
ffffffffc0200cc6:	439c                	lw	a5,0(a5)
ffffffffc0200cc8:	97ba                	add	a5,a5,a4
ffffffffc0200cca:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200ccc:	00005517          	auipc	a0,0x5
ffffffffc0200cd0:	57450513          	addi	a0,a0,1396 # ffffffffc0206240 <commands+0x720>
ffffffffc0200cd4:	cc0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200cd8:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cdc:	60a6                	ld	ra,72(sp)
ffffffffc0200cde:	74e2                	ld	s1,56(sp)
        tf->epc += 4;
ffffffffc0200ce0:	0791                	addi	a5,a5,4
ffffffffc0200ce2:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200ce6:	6406                	ld	s0,64(sp)
ffffffffc0200ce8:	7942                	ld	s2,48(sp)
ffffffffc0200cea:	79a2                	ld	s3,40(sp)
ffffffffc0200cec:	7a02                	ld	s4,32(sp)
ffffffffc0200cee:	6ae2                	ld	s5,24(sp)
ffffffffc0200cf0:	6b42                	ld	s6,16(sp)
ffffffffc0200cf2:	6ba2                	ld	s7,8(sp)
ffffffffc0200cf4:	6161                	addi	sp,sp,80
        syscall();
ffffffffc0200cf6:	66c0406f          	j	ffffffffc0205362 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cfa:	00005517          	auipc	a0,0x5
ffffffffc0200cfe:	56650513          	addi	a0,a0,1382 # ffffffffc0206260 <commands+0x740>
}
ffffffffc0200d02:	6406                	ld	s0,64(sp)
ffffffffc0200d04:	60a6                	ld	ra,72(sp)
ffffffffc0200d06:	74e2                	ld	s1,56(sp)
ffffffffc0200d08:	7942                	ld	s2,48(sp)
ffffffffc0200d0a:	79a2                	ld	s3,40(sp)
ffffffffc0200d0c:	7a02                	ld	s4,32(sp)
ffffffffc0200d0e:	6ae2                	ld	s5,24(sp)
ffffffffc0200d10:	6b42                	ld	s6,16(sp)
ffffffffc0200d12:	6ba2                	ld	s7,8(sp)
ffffffffc0200d14:	6161                	addi	sp,sp,80
        cprintf("Instruction access fault\n");
ffffffffc0200d16:	c7eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d1a:	00005517          	auipc	a0,0x5
ffffffffc0200d1e:	56650513          	addi	a0,a0,1382 # ffffffffc0206280 <commands+0x760>
ffffffffc0200d22:	b7c5                	j	ffffffffc0200d02 <exception_handler+0x68>
        cprintf("Instruction page fault\n");
ffffffffc0200d24:	00005517          	auipc	a0,0x5
ffffffffc0200d28:	57c50513          	addi	a0,a0,1404 # ffffffffc02062a0 <commands+0x780>
ffffffffc0200d2c:	bfd9                	j	ffffffffc0200d02 <exception_handler+0x68>
        cprintf("Load page fault\n");
ffffffffc0200d2e:	00005517          	auipc	a0,0x5
ffffffffc0200d32:	58a50513          	addi	a0,a0,1418 # ffffffffc02062b8 <commands+0x798>
ffffffffc0200d36:	b7f1                	j	ffffffffc0200d02 <exception_handler+0x68>
            struct mm_struct *mm = current->mm;
ffffffffc0200d38:	000aa797          	auipc	a5,0xaa
ffffffffc0200d3c:	9f07b783          	ld	a5,-1552(a5) # ffffffffc02aa728 <current>
ffffffffc0200d40:	0287b903          	ld	s2,40(a5)
            uintptr_t addr = tf->tval;  // 获取触发异常的地址
ffffffffc0200d44:	11053483          	ld	s1,272(a0)
            ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0200d48:	4601                	li	a2,0
ffffffffc0200d4a:	01893503          	ld	a0,24(s2)
ffffffffc0200d4e:	85a6                	mv	a1,s1
ffffffffc0200d50:	3e4010ef          	jal	ra,ffffffffc0202134 <get_pte>
ffffffffc0200d54:	89aa                	mv	s3,a0
            if (ptep && (*ptep & PTE_V) && !(*ptep & PTE_W)) {
ffffffffc0200d56:	1c050a63          	beqz	a0,ffffffffc0200f2a <exception_handler+0x290>
ffffffffc0200d5a:	00053a03          	ld	s4,0(a0)
ffffffffc0200d5e:	4785                	li	a5,1
ffffffffc0200d60:	005a7a13          	andi	s4,s4,5
ffffffffc0200d64:	1cfa1363          	bne	s4,a5,ffffffffc0200f2a <exception_handler+0x290>
                struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0200d68:	85a6                	mv	a1,s1
ffffffffc0200d6a:	854a                	mv	a0,s2
ffffffffc0200d6c:	3a1020ef          	jal	ra,ffffffffc020390c <find_vma>
                if (vma && (vma->vm_flags & VM_WRITE)) {
ffffffffc0200d70:	1a050d63          	beqz	a0,ffffffffc0200f2a <exception_handler+0x290>
ffffffffc0200d74:	4d1c                	lw	a5,24(a0)
ffffffffc0200d76:	8b89                	andi	a5,a5,2
ffffffffc0200d78:	1a078963          	beqz	a5,ffffffffc0200f2a <exception_handler+0x290>
                    struct Page *page = pte2page(*ptep);
ffffffffc0200d7c:	0009b983          	ld	s3,0(s3)
}

static inline struct Page *
pte2page(pte_t pte)
{
    if (!(pte & PTE_V))
ffffffffc0200d80:	0019f793          	andi	a5,s3,1
ffffffffc0200d84:	1c078c63          	beqz	a5,ffffffffc0200f5c <exception_handler+0x2c2>
    if (PPN(pa) >= npage)
ffffffffc0200d88:	000aab17          	auipc	s6,0xaa
ffffffffc0200d8c:	980b0b13          	addi	s6,s6,-1664 # ffffffffc02aa708 <npage>
ffffffffc0200d90:	000b3783          	ld	a5,0(s6)
    {
        panic("pte2page called with invalid pte");
    }
    return pa2page(PTE_ADDR(pte));
ffffffffc0200d94:	00299713          	slli	a4,s3,0x2
ffffffffc0200d98:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0200d9a:	1cf77d63          	bgeu	a4,a5,ffffffffc0200f74 <exception_handler+0x2da>
    return &pages[PPN(pa) - nbase];
ffffffffc0200d9e:	000aab97          	auipc	s7,0xaa
ffffffffc0200da2:	972b8b93          	addi	s7,s7,-1678 # ffffffffc02aa710 <pages>
ffffffffc0200da6:	000bb403          	ld	s0,0(s7)
ffffffffc0200daa:	00007a97          	auipc	s5,0x7
ffffffffc0200dae:	c76aba83          	ld	s5,-906(s5) # ffffffffc0207a20 <nbase>
ffffffffc0200db2:	41570733          	sub	a4,a4,s5
ffffffffc0200db6:	071a                	slli	a4,a4,0x6
ffffffffc0200db8:	943a                	add	s0,s0,a4
                    if (page_ref(page) == 1) {
ffffffffc0200dba:	401c                	lw	a5,0(s0)
                    uint32_t perm = (*ptep & PTE_USER);
ffffffffc0200dbc:	01f9f993          	andi	s3,s3,31
                    if (page_ref(page) == 1) {
ffffffffc0200dc0:	11478963          	beq	a5,s4,ffffffffc0200ed2 <exception_handler+0x238>
                        struct Page *npage = alloc_page();
ffffffffc0200dc4:	4505                	li	a0,1
ffffffffc0200dc6:	2b6010ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc0200dca:	8a2a                	mv	s4,a0
                        if (npage == NULL) {
ffffffffc0200dcc:	1c050d63          	beqz	a0,ffffffffc0200fa6 <exception_handler+0x30c>
    return page - pages + nbase;
ffffffffc0200dd0:	000bb783          	ld	a5,0(s7)
    return KADDR(page2pa(page));
ffffffffc0200dd4:	577d                	li	a4,-1
ffffffffc0200dd6:	000b3603          	ld	a2,0(s6)
    return page - pages + nbase;
ffffffffc0200dda:	40f506b3          	sub	a3,a0,a5
ffffffffc0200dde:	8699                	srai	a3,a3,0x6
ffffffffc0200de0:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc0200de2:	8331                	srli	a4,a4,0xc
ffffffffc0200de4:	00e6f5b3          	and	a1,a3,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0200de8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0200dea:	1ac5f263          	bgeu	a1,a2,ffffffffc0200f8e <exception_handler+0x2f4>
    return page - pages + nbase;
ffffffffc0200dee:	40f407b3          	sub	a5,s0,a5
ffffffffc0200df2:	8799                	srai	a5,a5,0x6
ffffffffc0200df4:	97d6                	add	a5,a5,s5
    return KADDR(page2pa(page));
ffffffffc0200df6:	000aa597          	auipc	a1,0xaa
ffffffffc0200dfa:	92a5b583          	ld	a1,-1750(a1) # ffffffffc02aa720 <va_pa_offset>
ffffffffc0200dfe:	8f7d                	and	a4,a4,a5
ffffffffc0200e00:	00b68533          	add	a0,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e04:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0200e06:	18c77363          	bgeu	a4,a2,ffffffffc0200f8c <exception_handler+0x2f2>
                        memcpy(page2kva(npage), page2kva(page), PGSIZE);
ffffffffc0200e0a:	6605                	lui	a2,0x1
ffffffffc0200e0c:	95be                	add	a1,a1,a5
ffffffffc0200e0e:	28d040ef          	jal	ra,ffffffffc020589a <memcpy>
                        if (page_insert(mm->pgdir, npage, addr, perm | PTE_W) != 0) {
ffffffffc0200e12:	01893503          	ld	a0,24(s2)
ffffffffc0200e16:	0049e693          	ori	a3,s3,4
ffffffffc0200e1a:	8626                	mv	a2,s1
ffffffffc0200e1c:	85d2                	mv	a1,s4
ffffffffc0200e1e:	207010ef          	jal	ra,ffffffffc0202824 <page_insert>
ffffffffc0200e22:	c531                	beqz	a0,ffffffffc0200e6e <exception_handler+0x1d4>
                            panic("COW: page_insert failed");
ffffffffc0200e24:	00005617          	auipc	a2,0x5
ffffffffc0200e28:	54460613          	addi	a2,a2,1348 # ffffffffc0206368 <commands+0x848>
ffffffffc0200e2c:	0f700593          	li	a1,247
ffffffffc0200e30:	00005517          	auipc	a0,0x5
ffffffffc0200e34:	3e050513          	addi	a0,a0,992 # ffffffffc0206210 <commands+0x6f0>
ffffffffc0200e38:	e56ff0ef          	jal	ra,ffffffffc020048e <__panic>
        cprintf("Instruction address misaligned\n");
ffffffffc0200e3c:	00005517          	auipc	a0,0x5
ffffffffc0200e40:	31c50513          	addi	a0,a0,796 # ffffffffc0206158 <commands+0x638>
ffffffffc0200e44:	bd7d                	j	ffffffffc0200d02 <exception_handler+0x68>
        cprintf("Instruction access fault\n");
ffffffffc0200e46:	00005517          	auipc	a0,0x5
ffffffffc0200e4a:	33250513          	addi	a0,a0,818 # ffffffffc0206178 <commands+0x658>
ffffffffc0200e4e:	bd55                	j	ffffffffc0200d02 <exception_handler+0x68>
        cprintf("Illegal instruction\n");
ffffffffc0200e50:	00005517          	auipc	a0,0x5
ffffffffc0200e54:	34850513          	addi	a0,a0,840 # ffffffffc0206198 <commands+0x678>
ffffffffc0200e58:	b56d                	j	ffffffffc0200d02 <exception_handler+0x68>
        cprintf("Breakpoint\n");
ffffffffc0200e5a:	00005517          	auipc	a0,0x5
ffffffffc0200e5e:	35650513          	addi	a0,a0,854 # ffffffffc02061b0 <commands+0x690>
ffffffffc0200e62:	b32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200e66:	6458                	ld	a4,136(s0)
ffffffffc0200e68:	47a9                	li	a5,10
ffffffffc0200e6a:	08f70663          	beq	a4,a5,ffffffffc0200ef6 <exception_handler+0x25c>
}
ffffffffc0200e6e:	60a6                	ld	ra,72(sp)
ffffffffc0200e70:	6406                	ld	s0,64(sp)
ffffffffc0200e72:	74e2                	ld	s1,56(sp)
ffffffffc0200e74:	7942                	ld	s2,48(sp)
ffffffffc0200e76:	79a2                	ld	s3,40(sp)
ffffffffc0200e78:	7a02                	ld	s4,32(sp)
ffffffffc0200e7a:	6ae2                	ld	s5,24(sp)
ffffffffc0200e7c:	6b42                	ld	s6,16(sp)
ffffffffc0200e7e:	6ba2                	ld	s7,8(sp)
ffffffffc0200e80:	6161                	addi	sp,sp,80
ffffffffc0200e82:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200e84:	00005517          	auipc	a0,0x5
ffffffffc0200e88:	33c50513          	addi	a0,a0,828 # ffffffffc02061c0 <commands+0x6a0>
ffffffffc0200e8c:	bd9d                	j	ffffffffc0200d02 <exception_handler+0x68>
        cprintf("Load access fault\n");
ffffffffc0200e8e:	00005517          	auipc	a0,0x5
ffffffffc0200e92:	35250513          	addi	a0,a0,850 # ffffffffc02061e0 <commands+0x6c0>
ffffffffc0200e96:	b5b5                	j	ffffffffc0200d02 <exception_handler+0x68>
        cprintf("Store/AMO access fault\n");
ffffffffc0200e98:	00005517          	auipc	a0,0x5
ffffffffc0200e9c:	39050513          	addi	a0,a0,912 # ffffffffc0206228 <commands+0x708>
ffffffffc0200ea0:	b58d                	j	ffffffffc0200d02 <exception_handler+0x68>
        print_trapframe(tf);
ffffffffc0200ea2:	8522                	mv	a0,s0
}
ffffffffc0200ea4:	6406                	ld	s0,64(sp)
ffffffffc0200ea6:	60a6                	ld	ra,72(sp)
ffffffffc0200ea8:	74e2                	ld	s1,56(sp)
ffffffffc0200eaa:	7942                	ld	s2,48(sp)
ffffffffc0200eac:	79a2                	ld	s3,40(sp)
ffffffffc0200eae:	7a02                	ld	s4,32(sp)
ffffffffc0200eb0:	6ae2                	ld	s5,24(sp)
ffffffffc0200eb2:	6b42                	ld	s6,16(sp)
ffffffffc0200eb4:	6ba2                	ld	s7,8(sp)
ffffffffc0200eb6:	6161                	addi	sp,sp,80
        print_trapframe(tf);
ffffffffc0200eb8:	b1f5                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200eba:	00005617          	auipc	a2,0x5
ffffffffc0200ebe:	33e60613          	addi	a2,a2,830 # ffffffffc02061f8 <commands+0x6d8>
ffffffffc0200ec2:	0c300593          	li	a1,195
ffffffffc0200ec6:	00005517          	auipc	a0,0x5
ffffffffc0200eca:	34a50513          	addi	a0,a0,842 # ffffffffc0206210 <commands+0x6f0>
ffffffffc0200ece:	dc0ff0ef          	jal	ra,ffffffffc020048e <__panic>
                        page_insert(mm->pgdir, page, addr, perm | PTE_W);
ffffffffc0200ed2:	85a2                	mv	a1,s0
}
ffffffffc0200ed4:	6406                	ld	s0,64(sp)
                        page_insert(mm->pgdir, page, addr, perm | PTE_W);
ffffffffc0200ed6:	01893503          	ld	a0,24(s2)
}
ffffffffc0200eda:	60a6                	ld	ra,72(sp)
ffffffffc0200edc:	7942                	ld	s2,48(sp)
ffffffffc0200ede:	7a02                	ld	s4,32(sp)
ffffffffc0200ee0:	6ae2                	ld	s5,24(sp)
ffffffffc0200ee2:	6b42                	ld	s6,16(sp)
ffffffffc0200ee4:	6ba2                	ld	s7,8(sp)
                        page_insert(mm->pgdir, page, addr, perm | PTE_W);
ffffffffc0200ee6:	0049e693          	ori	a3,s3,4
ffffffffc0200eea:	8626                	mv	a2,s1
}
ffffffffc0200eec:	79a2                	ld	s3,40(sp)
ffffffffc0200eee:	74e2                	ld	s1,56(sp)
ffffffffc0200ef0:	6161                	addi	sp,sp,80
                        page_insert(mm->pgdir, page, addr, perm | PTE_W);
ffffffffc0200ef2:	1330106f          	j	ffffffffc0202824 <page_insert>
            tf->epc += 4;
ffffffffc0200ef6:	10843783          	ld	a5,264(s0)
ffffffffc0200efa:	0791                	addi	a5,a5,4
ffffffffc0200efc:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200f00:	462040ef          	jal	ra,ffffffffc0205362 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200f04:	000aa797          	auipc	a5,0xaa
ffffffffc0200f08:	8247b783          	ld	a5,-2012(a5) # ffffffffc02aa728 <current>
ffffffffc0200f0c:	6b9c                	ld	a5,16(a5)
ffffffffc0200f0e:	8522                	mv	a0,s0
}
ffffffffc0200f10:	6406                	ld	s0,64(sp)
ffffffffc0200f12:	60a6                	ld	ra,72(sp)
ffffffffc0200f14:	74e2                	ld	s1,56(sp)
ffffffffc0200f16:	7942                	ld	s2,48(sp)
ffffffffc0200f18:	79a2                	ld	s3,40(sp)
ffffffffc0200f1a:	7a02                	ld	s4,32(sp)
ffffffffc0200f1c:	6ae2                	ld	s5,24(sp)
ffffffffc0200f1e:	6b42                	ld	s6,16(sp)
ffffffffc0200f20:	6ba2                	ld	s7,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200f22:	6589                	lui	a1,0x2
ffffffffc0200f24:	95be                	add	a1,a1,a5
}
ffffffffc0200f26:	6161                	addi	sp,sp,80
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200f28:	a2fd                	j	ffffffffc0201116 <kernel_execve_ret>
            cprintf("Store fault at %p (epc: %p)\n", tf->tval, tf->epc);
ffffffffc0200f2a:	10843603          	ld	a2,264(s0)
ffffffffc0200f2e:	11043583          	ld	a1,272(s0)
ffffffffc0200f32:	00005517          	auipc	a0,0x5
ffffffffc0200f36:	44e50513          	addi	a0,a0,1102 # ffffffffc0206380 <commands+0x860>
ffffffffc0200f3a:	a5aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            print_trapframe(tf);
ffffffffc0200f3e:	8522                	mv	a0,s0
ffffffffc0200f40:	c65ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            panic("handle pgfault failed");
ffffffffc0200f44:	00005617          	auipc	a2,0x5
ffffffffc0200f48:	45c60613          	addi	a2,a2,1116 # ffffffffc02063a0 <commands+0x880>
ffffffffc0200f4c:	10000593          	li	a1,256
ffffffffc0200f50:	00005517          	auipc	a0,0x5
ffffffffc0200f54:	2c050513          	addi	a0,a0,704 # ffffffffc0206210 <commands+0x6f0>
ffffffffc0200f58:	d36ff0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0200f5c:	00005617          	auipc	a2,0x5
ffffffffc0200f60:	37460613          	addi	a2,a2,884 # ffffffffc02062d0 <commands+0x7b0>
ffffffffc0200f64:	07f00593          	li	a1,127
ffffffffc0200f68:	00005517          	auipc	a0,0x5
ffffffffc0200f6c:	39050513          	addi	a0,a0,912 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc0200f70:	d1eff0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0200f74:	00005617          	auipc	a2,0x5
ffffffffc0200f78:	39460613          	addi	a2,a2,916 # ffffffffc0206308 <commands+0x7e8>
ffffffffc0200f7c:	06900593          	li	a1,105
ffffffffc0200f80:	00005517          	auipc	a0,0x5
ffffffffc0200f84:	37850513          	addi	a0,a0,888 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc0200f88:	d06ff0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0200f8c:	86be                	mv	a3,a5
ffffffffc0200f8e:	00005617          	auipc	a2,0x5
ffffffffc0200f92:	3b260613          	addi	a2,a2,946 # ffffffffc0206340 <commands+0x820>
ffffffffc0200f96:	07100593          	li	a1,113
ffffffffc0200f9a:	00005517          	auipc	a0,0x5
ffffffffc0200f9e:	35e50513          	addi	a0,a0,862 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc0200fa2:	cecff0ef          	jal	ra,ffffffffc020048e <__panic>
                            panic("COW: out of memory");
ffffffffc0200fa6:	00005617          	auipc	a2,0x5
ffffffffc0200faa:	38260613          	addi	a2,a2,898 # ffffffffc0206328 <commands+0x808>
ffffffffc0200fae:	0f300593          	li	a1,243
ffffffffc0200fb2:	00005517          	auipc	a0,0x5
ffffffffc0200fb6:	25e50513          	addi	a0,a0,606 # ffffffffc0206210 <commands+0x6f0>
ffffffffc0200fba:	cd4ff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200fbe <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200fbe:	1101                	addi	sp,sp,-32
ffffffffc0200fc0:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200fc2:	000a9417          	auipc	s0,0xa9
ffffffffc0200fc6:	76640413          	addi	s0,s0,1894 # ffffffffc02aa728 <current>
ffffffffc0200fca:	6018                	ld	a4,0(s0)
{
ffffffffc0200fcc:	ec06                	sd	ra,24(sp)
ffffffffc0200fce:	e426                	sd	s1,8(sp)
ffffffffc0200fd0:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200fd2:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200fd6:	cf1d                	beqz	a4,ffffffffc0201014 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200fd8:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200fdc:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200fe0:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200fe2:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200fe6:	0206c463          	bltz	a3,ffffffffc020100e <trap+0x50>
        exception_handler(tf);
ffffffffc0200fea:	cb1ff0ef          	jal	ra,ffffffffc0200c9a <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200fee:	601c                	ld	a5,0(s0)
ffffffffc0200ff0:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200ff4:	e499                	bnez	s1,ffffffffc0201002 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200ff6:	0b07a703          	lw	a4,176(a5)
ffffffffc0200ffa:	8b05                	andi	a4,a4,1
ffffffffc0200ffc:	e329                	bnez	a4,ffffffffc020103e <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200ffe:	6f9c                	ld	a5,24(a5)
ffffffffc0201000:	eb85                	bnez	a5,ffffffffc0201030 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0201002:	60e2                	ld	ra,24(sp)
ffffffffc0201004:	6442                	ld	s0,16(sp)
ffffffffc0201006:	64a2                	ld	s1,8(sp)
ffffffffc0201008:	6902                	ld	s2,0(sp)
ffffffffc020100a:	6105                	addi	sp,sp,32
ffffffffc020100c:	8082                	ret
        interrupt_handler(tf);
ffffffffc020100e:	bf9ff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0201012:	bff1                	j	ffffffffc0200fee <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0201014:	0006c863          	bltz	a3,ffffffffc0201024 <trap+0x66>
}
ffffffffc0201018:	6442                	ld	s0,16(sp)
ffffffffc020101a:	60e2                	ld	ra,24(sp)
ffffffffc020101c:	64a2                	ld	s1,8(sp)
ffffffffc020101e:	6902                	ld	s2,0(sp)
ffffffffc0201020:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0201022:	b9a5                	j	ffffffffc0200c9a <exception_handler>
}
ffffffffc0201024:	6442                	ld	s0,16(sp)
ffffffffc0201026:	60e2                	ld	ra,24(sp)
ffffffffc0201028:	64a2                	ld	s1,8(sp)
ffffffffc020102a:	6902                	ld	s2,0(sp)
ffffffffc020102c:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc020102e:	bee1                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0201030:	6442                	ld	s0,16(sp)
ffffffffc0201032:	60e2                	ld	ra,24(sp)
ffffffffc0201034:	64a2                	ld	s1,8(sp)
ffffffffc0201036:	6902                	ld	s2,0(sp)
ffffffffc0201038:	6105                	addi	sp,sp,32
                schedule();
ffffffffc020103a:	23c0406f          	j	ffffffffc0205276 <schedule>
                do_exit(-E_KILLED);
ffffffffc020103e:	555d                	li	a0,-9
ffffffffc0201040:	57c030ef          	jal	ra,ffffffffc02045bc <do_exit>
            if (current->need_resched)
ffffffffc0201044:	601c                	ld	a5,0(s0)
ffffffffc0201046:	bf65                	j	ffffffffc0200ffe <trap+0x40>

ffffffffc0201048 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0201048:	14011173          	csrrw	sp,sscratch,sp
ffffffffc020104c:	00011463          	bnez	sp,ffffffffc0201054 <__alltraps+0xc>
ffffffffc0201050:	14002173          	csrr	sp,sscratch
ffffffffc0201054:	712d                	addi	sp,sp,-288
ffffffffc0201056:	e002                	sd	zero,0(sp)
ffffffffc0201058:	e406                	sd	ra,8(sp)
ffffffffc020105a:	ec0e                	sd	gp,24(sp)
ffffffffc020105c:	f012                	sd	tp,32(sp)
ffffffffc020105e:	f416                	sd	t0,40(sp)
ffffffffc0201060:	f81a                	sd	t1,48(sp)
ffffffffc0201062:	fc1e                	sd	t2,56(sp)
ffffffffc0201064:	e0a2                	sd	s0,64(sp)
ffffffffc0201066:	e4a6                	sd	s1,72(sp)
ffffffffc0201068:	e8aa                	sd	a0,80(sp)
ffffffffc020106a:	ecae                	sd	a1,88(sp)
ffffffffc020106c:	f0b2                	sd	a2,96(sp)
ffffffffc020106e:	f4b6                	sd	a3,104(sp)
ffffffffc0201070:	f8ba                	sd	a4,112(sp)
ffffffffc0201072:	fcbe                	sd	a5,120(sp)
ffffffffc0201074:	e142                	sd	a6,128(sp)
ffffffffc0201076:	e546                	sd	a7,136(sp)
ffffffffc0201078:	e94a                	sd	s2,144(sp)
ffffffffc020107a:	ed4e                	sd	s3,152(sp)
ffffffffc020107c:	f152                	sd	s4,160(sp)
ffffffffc020107e:	f556                	sd	s5,168(sp)
ffffffffc0201080:	f95a                	sd	s6,176(sp)
ffffffffc0201082:	fd5e                	sd	s7,184(sp)
ffffffffc0201084:	e1e2                	sd	s8,192(sp)
ffffffffc0201086:	e5e6                	sd	s9,200(sp)
ffffffffc0201088:	e9ea                	sd	s10,208(sp)
ffffffffc020108a:	edee                	sd	s11,216(sp)
ffffffffc020108c:	f1f2                	sd	t3,224(sp)
ffffffffc020108e:	f5f6                	sd	t4,232(sp)
ffffffffc0201090:	f9fa                	sd	t5,240(sp)
ffffffffc0201092:	fdfe                	sd	t6,248(sp)
ffffffffc0201094:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0201098:	100024f3          	csrr	s1,sstatus
ffffffffc020109c:	14102973          	csrr	s2,sepc
ffffffffc02010a0:	143029f3          	csrr	s3,stval
ffffffffc02010a4:	14202a73          	csrr	s4,scause
ffffffffc02010a8:	e822                	sd	s0,16(sp)
ffffffffc02010aa:	e226                	sd	s1,256(sp)
ffffffffc02010ac:	e64a                	sd	s2,264(sp)
ffffffffc02010ae:	ea4e                	sd	s3,272(sp)
ffffffffc02010b0:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02010b2:	850a                	mv	a0,sp
    jal trap
ffffffffc02010b4:	f0bff0ef          	jal	ra,ffffffffc0200fbe <trap>

ffffffffc02010b8 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02010b8:	6492                	ld	s1,256(sp)
ffffffffc02010ba:	6932                	ld	s2,264(sp)
ffffffffc02010bc:	1004f413          	andi	s0,s1,256
ffffffffc02010c0:	e401                	bnez	s0,ffffffffc02010c8 <__trapret+0x10>
ffffffffc02010c2:	1200                	addi	s0,sp,288
ffffffffc02010c4:	14041073          	csrw	sscratch,s0
ffffffffc02010c8:	10049073          	csrw	sstatus,s1
ffffffffc02010cc:	14191073          	csrw	sepc,s2
ffffffffc02010d0:	60a2                	ld	ra,8(sp)
ffffffffc02010d2:	61e2                	ld	gp,24(sp)
ffffffffc02010d4:	7202                	ld	tp,32(sp)
ffffffffc02010d6:	72a2                	ld	t0,40(sp)
ffffffffc02010d8:	7342                	ld	t1,48(sp)
ffffffffc02010da:	73e2                	ld	t2,56(sp)
ffffffffc02010dc:	6406                	ld	s0,64(sp)
ffffffffc02010de:	64a6                	ld	s1,72(sp)
ffffffffc02010e0:	6546                	ld	a0,80(sp)
ffffffffc02010e2:	65e6                	ld	a1,88(sp)
ffffffffc02010e4:	7606                	ld	a2,96(sp)
ffffffffc02010e6:	76a6                	ld	a3,104(sp)
ffffffffc02010e8:	7746                	ld	a4,112(sp)
ffffffffc02010ea:	77e6                	ld	a5,120(sp)
ffffffffc02010ec:	680a                	ld	a6,128(sp)
ffffffffc02010ee:	68aa                	ld	a7,136(sp)
ffffffffc02010f0:	694a                	ld	s2,144(sp)
ffffffffc02010f2:	69ea                	ld	s3,152(sp)
ffffffffc02010f4:	7a0a                	ld	s4,160(sp)
ffffffffc02010f6:	7aaa                	ld	s5,168(sp)
ffffffffc02010f8:	7b4a                	ld	s6,176(sp)
ffffffffc02010fa:	7bea                	ld	s7,184(sp)
ffffffffc02010fc:	6c0e                	ld	s8,192(sp)
ffffffffc02010fe:	6cae                	ld	s9,200(sp)
ffffffffc0201100:	6d4e                	ld	s10,208(sp)
ffffffffc0201102:	6dee                	ld	s11,216(sp)
ffffffffc0201104:	7e0e                	ld	t3,224(sp)
ffffffffc0201106:	7eae                	ld	t4,232(sp)
ffffffffc0201108:	7f4e                	ld	t5,240(sp)
ffffffffc020110a:	7fee                	ld	t6,248(sp)
ffffffffc020110c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc020110e:	10200073          	sret

ffffffffc0201112 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0201112:	812a                	mv	sp,a0
    j __trapret
ffffffffc0201114:	b755                	j	ffffffffc02010b8 <__trapret>

ffffffffc0201116 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0201116:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc8>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc020111a:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc020111e:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0201122:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0201126:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc020112a:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc020112e:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0201132:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0201136:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc020113a:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc020113c:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc020113e:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0201140:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0201142:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0201144:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0201146:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0201148:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc020114a:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc020114c:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc020114e:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0201150:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0201152:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0201154:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0201156:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0201158:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc020115a:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc020115c:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc020115e:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0201160:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0201162:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0201164:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0201166:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0201168:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc020116a:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc020116c:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc020116e:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0201170:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0201172:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0201174:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0201176:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0201178:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc020117a:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc020117c:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc020117e:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0201180:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0201182:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0201184:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0201186:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0201188:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc020118a:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc020118c:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc020118e:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0201190:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0201192:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0201194:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0201196:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0201198:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc020119a:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc020119c:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc020119e:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc02011a0:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc02011a2:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc02011a4:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc02011a6:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc02011a8:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc02011aa:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc02011ac:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc02011ae:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc02011b0:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc02011b2:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc02011b4:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc02011b6:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc02011b8:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc02011ba:	812e                	mv	sp,a1
ffffffffc02011bc:	bdf5                	j	ffffffffc02010b8 <__trapret>

ffffffffc02011be <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02011be:	000a5797          	auipc	a5,0xa5
ffffffffc02011c2:	4e278793          	addi	a5,a5,1250 # ffffffffc02a66a0 <free_area>
ffffffffc02011c6:	e79c                	sd	a5,8(a5)
ffffffffc02011c8:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc02011ca:	0007a823          	sw	zero,16(a5)
}
ffffffffc02011ce:	8082                	ret

ffffffffc02011d0 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc02011d0:	000a5517          	auipc	a0,0xa5
ffffffffc02011d4:	4e056503          	lwu	a0,1248(a0) # ffffffffc02a66b0 <free_area+0x10>
ffffffffc02011d8:	8082                	ret

ffffffffc02011da <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc02011da:	715d                	addi	sp,sp,-80
ffffffffc02011dc:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02011de:	000a5417          	auipc	s0,0xa5
ffffffffc02011e2:	4c240413          	addi	s0,s0,1218 # ffffffffc02a66a0 <free_area>
ffffffffc02011e6:	641c                	ld	a5,8(s0)
ffffffffc02011e8:	e486                	sd	ra,72(sp)
ffffffffc02011ea:	fc26                	sd	s1,56(sp)
ffffffffc02011ec:	f84a                	sd	s2,48(sp)
ffffffffc02011ee:	f44e                	sd	s3,40(sp)
ffffffffc02011f0:	f052                	sd	s4,32(sp)
ffffffffc02011f2:	ec56                	sd	s5,24(sp)
ffffffffc02011f4:	e85a                	sd	s6,16(sp)
ffffffffc02011f6:	e45e                	sd	s7,8(sp)
ffffffffc02011f8:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02011fa:	2a878d63          	beq	a5,s0,ffffffffc02014b4 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc02011fe:	4481                	li	s1,0
ffffffffc0201200:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201202:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201206:	8b09                	andi	a4,a4,2
ffffffffc0201208:	2a070a63          	beqz	a4,ffffffffc02014bc <default_check+0x2e2>
        count++, total += p->property;
ffffffffc020120c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201210:	679c                	ld	a5,8(a5)
ffffffffc0201212:	2905                	addiw	s2,s2,1
ffffffffc0201214:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201216:	fe8796e3          	bne	a5,s0,ffffffffc0201202 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc020121a:	89a6                	mv	s3,s1
ffffffffc020121c:	6df000ef          	jal	ra,ffffffffc02020fa <nr_free_pages>
ffffffffc0201220:	6f351e63          	bne	a0,s3,ffffffffc020191c <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201224:	4505                	li	a0,1
ffffffffc0201226:	657000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc020122a:	8aaa                	mv	s5,a0
ffffffffc020122c:	42050863          	beqz	a0,ffffffffc020165c <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201230:	4505                	li	a0,1
ffffffffc0201232:	64b000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc0201236:	89aa                	mv	s3,a0
ffffffffc0201238:	70050263          	beqz	a0,ffffffffc020193c <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020123c:	4505                	li	a0,1
ffffffffc020123e:	63f000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc0201242:	8a2a                	mv	s4,a0
ffffffffc0201244:	48050c63          	beqz	a0,ffffffffc02016dc <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201248:	293a8a63          	beq	s5,s3,ffffffffc02014dc <default_check+0x302>
ffffffffc020124c:	28aa8863          	beq	s5,a0,ffffffffc02014dc <default_check+0x302>
ffffffffc0201250:	28a98663          	beq	s3,a0,ffffffffc02014dc <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201254:	000aa783          	lw	a5,0(s5)
ffffffffc0201258:	2a079263          	bnez	a5,ffffffffc02014fc <default_check+0x322>
ffffffffc020125c:	0009a783          	lw	a5,0(s3)
ffffffffc0201260:	28079e63          	bnez	a5,ffffffffc02014fc <default_check+0x322>
ffffffffc0201264:	411c                	lw	a5,0(a0)
ffffffffc0201266:	28079b63          	bnez	a5,ffffffffc02014fc <default_check+0x322>
    return page - pages + nbase;
ffffffffc020126a:	000a9797          	auipc	a5,0xa9
ffffffffc020126e:	4a67b783          	ld	a5,1190(a5) # ffffffffc02aa710 <pages>
ffffffffc0201272:	40fa8733          	sub	a4,s5,a5
ffffffffc0201276:	00006617          	auipc	a2,0x6
ffffffffc020127a:	7aa63603          	ld	a2,1962(a2) # ffffffffc0207a20 <nbase>
ffffffffc020127e:	8719                	srai	a4,a4,0x6
ffffffffc0201280:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201282:	000a9697          	auipc	a3,0xa9
ffffffffc0201286:	4866b683          	ld	a3,1158(a3) # ffffffffc02aa708 <npage>
ffffffffc020128a:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020128c:	0732                	slli	a4,a4,0xc
ffffffffc020128e:	28d77763          	bgeu	a4,a3,ffffffffc020151c <default_check+0x342>
    return page - pages + nbase;
ffffffffc0201292:	40f98733          	sub	a4,s3,a5
ffffffffc0201296:	8719                	srai	a4,a4,0x6
ffffffffc0201298:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020129a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020129c:	4cd77063          	bgeu	a4,a3,ffffffffc020175c <default_check+0x582>
    return page - pages + nbase;
ffffffffc02012a0:	40f507b3          	sub	a5,a0,a5
ffffffffc02012a4:	8799                	srai	a5,a5,0x6
ffffffffc02012a6:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02012a8:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02012aa:	30d7f963          	bgeu	a5,a3,ffffffffc02015bc <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc02012ae:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02012b0:	00043c03          	ld	s8,0(s0)
ffffffffc02012b4:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02012b8:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02012bc:	e400                	sd	s0,8(s0)
ffffffffc02012be:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02012c0:	000a5797          	auipc	a5,0xa5
ffffffffc02012c4:	3e07a823          	sw	zero,1008(a5) # ffffffffc02a66b0 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02012c8:	5b5000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc02012cc:	2c051863          	bnez	a0,ffffffffc020159c <default_check+0x3c2>
    free_page(p0);
ffffffffc02012d0:	4585                	li	a1,1
ffffffffc02012d2:	8556                	mv	a0,s5
ffffffffc02012d4:	5e7000ef          	jal	ra,ffffffffc02020ba <free_pages>
    free_page(p1);
ffffffffc02012d8:	4585                	li	a1,1
ffffffffc02012da:	854e                	mv	a0,s3
ffffffffc02012dc:	5df000ef          	jal	ra,ffffffffc02020ba <free_pages>
    free_page(p2);
ffffffffc02012e0:	4585                	li	a1,1
ffffffffc02012e2:	8552                	mv	a0,s4
ffffffffc02012e4:	5d7000ef          	jal	ra,ffffffffc02020ba <free_pages>
    assert(nr_free == 3);
ffffffffc02012e8:	4818                	lw	a4,16(s0)
ffffffffc02012ea:	478d                	li	a5,3
ffffffffc02012ec:	28f71863          	bne	a4,a5,ffffffffc020157c <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02012f0:	4505                	li	a0,1
ffffffffc02012f2:	58b000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc02012f6:	89aa                	mv	s3,a0
ffffffffc02012f8:	26050263          	beqz	a0,ffffffffc020155c <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02012fc:	4505                	li	a0,1
ffffffffc02012fe:	57f000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc0201302:	8aaa                	mv	s5,a0
ffffffffc0201304:	3a050c63          	beqz	a0,ffffffffc02016bc <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201308:	4505                	li	a0,1
ffffffffc020130a:	573000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc020130e:	8a2a                	mv	s4,a0
ffffffffc0201310:	38050663          	beqz	a0,ffffffffc020169c <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0201314:	4505                	li	a0,1
ffffffffc0201316:	567000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc020131a:	36051163          	bnez	a0,ffffffffc020167c <default_check+0x4a2>
    free_page(p0);
ffffffffc020131e:	4585                	li	a1,1
ffffffffc0201320:	854e                	mv	a0,s3
ffffffffc0201322:	599000ef          	jal	ra,ffffffffc02020ba <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201326:	641c                	ld	a5,8(s0)
ffffffffc0201328:	20878a63          	beq	a5,s0,ffffffffc020153c <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc020132c:	4505                	li	a0,1
ffffffffc020132e:	54f000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc0201332:	30a99563          	bne	s3,a0,ffffffffc020163c <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0201336:	4505                	li	a0,1
ffffffffc0201338:	545000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc020133c:	2e051063          	bnez	a0,ffffffffc020161c <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0201340:	481c                	lw	a5,16(s0)
ffffffffc0201342:	2a079d63          	bnez	a5,ffffffffc02015fc <default_check+0x422>
    free_page(p);
ffffffffc0201346:	854e                	mv	a0,s3
ffffffffc0201348:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020134a:	01843023          	sd	s8,0(s0)
ffffffffc020134e:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201352:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201356:	565000ef          	jal	ra,ffffffffc02020ba <free_pages>
    free_page(p1);
ffffffffc020135a:	4585                	li	a1,1
ffffffffc020135c:	8556                	mv	a0,s5
ffffffffc020135e:	55d000ef          	jal	ra,ffffffffc02020ba <free_pages>
    free_page(p2);
ffffffffc0201362:	4585                	li	a1,1
ffffffffc0201364:	8552                	mv	a0,s4
ffffffffc0201366:	555000ef          	jal	ra,ffffffffc02020ba <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020136a:	4515                	li	a0,5
ffffffffc020136c:	511000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc0201370:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201372:	26050563          	beqz	a0,ffffffffc02015dc <default_check+0x402>
ffffffffc0201376:	651c                	ld	a5,8(a0)
ffffffffc0201378:	8385                	srli	a5,a5,0x1
ffffffffc020137a:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc020137c:	54079063          	bnez	a5,ffffffffc02018bc <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201380:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201382:	00043b03          	ld	s6,0(s0)
ffffffffc0201386:	00843a83          	ld	s5,8(s0)
ffffffffc020138a:	e000                	sd	s0,0(s0)
ffffffffc020138c:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020138e:	4ef000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc0201392:	50051563          	bnez	a0,ffffffffc020189c <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201396:	08098a13          	addi	s4,s3,128
ffffffffc020139a:	8552                	mv	a0,s4
ffffffffc020139c:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020139e:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02013a2:	000a5797          	auipc	a5,0xa5
ffffffffc02013a6:	3007a723          	sw	zero,782(a5) # ffffffffc02a66b0 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02013aa:	511000ef          	jal	ra,ffffffffc02020ba <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02013ae:	4511                	li	a0,4
ffffffffc02013b0:	4cd000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc02013b4:	4c051463          	bnez	a0,ffffffffc020187c <default_check+0x6a2>
ffffffffc02013b8:	0889b783          	ld	a5,136(s3)
ffffffffc02013bc:	8385                	srli	a5,a5,0x1
ffffffffc02013be:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02013c0:	48078e63          	beqz	a5,ffffffffc020185c <default_check+0x682>
ffffffffc02013c4:	0909a703          	lw	a4,144(s3)
ffffffffc02013c8:	478d                	li	a5,3
ffffffffc02013ca:	48f71963          	bne	a4,a5,ffffffffc020185c <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02013ce:	450d                	li	a0,3
ffffffffc02013d0:	4ad000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc02013d4:	8c2a                	mv	s8,a0
ffffffffc02013d6:	46050363          	beqz	a0,ffffffffc020183c <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02013da:	4505                	li	a0,1
ffffffffc02013dc:	4a1000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc02013e0:	42051e63          	bnez	a0,ffffffffc020181c <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc02013e4:	418a1c63          	bne	s4,s8,ffffffffc02017fc <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02013e8:	4585                	li	a1,1
ffffffffc02013ea:	854e                	mv	a0,s3
ffffffffc02013ec:	4cf000ef          	jal	ra,ffffffffc02020ba <free_pages>
    free_pages(p1, 3);
ffffffffc02013f0:	458d                	li	a1,3
ffffffffc02013f2:	8552                	mv	a0,s4
ffffffffc02013f4:	4c7000ef          	jal	ra,ffffffffc02020ba <free_pages>
ffffffffc02013f8:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02013fc:	04098c13          	addi	s8,s3,64
ffffffffc0201400:	8385                	srli	a5,a5,0x1
ffffffffc0201402:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201404:	3c078c63          	beqz	a5,ffffffffc02017dc <default_check+0x602>
ffffffffc0201408:	0109a703          	lw	a4,16(s3)
ffffffffc020140c:	4785                	li	a5,1
ffffffffc020140e:	3cf71763          	bne	a4,a5,ffffffffc02017dc <default_check+0x602>
ffffffffc0201412:	008a3783          	ld	a5,8(s4)
ffffffffc0201416:	8385                	srli	a5,a5,0x1
ffffffffc0201418:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020141a:	3a078163          	beqz	a5,ffffffffc02017bc <default_check+0x5e2>
ffffffffc020141e:	010a2703          	lw	a4,16(s4)
ffffffffc0201422:	478d                	li	a5,3
ffffffffc0201424:	38f71c63          	bne	a4,a5,ffffffffc02017bc <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201428:	4505                	li	a0,1
ffffffffc020142a:	453000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc020142e:	36a99763          	bne	s3,a0,ffffffffc020179c <default_check+0x5c2>
    free_page(p0);
ffffffffc0201432:	4585                	li	a1,1
ffffffffc0201434:	487000ef          	jal	ra,ffffffffc02020ba <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201438:	4509                	li	a0,2
ffffffffc020143a:	443000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc020143e:	32aa1f63          	bne	s4,a0,ffffffffc020177c <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0201442:	4589                	li	a1,2
ffffffffc0201444:	477000ef          	jal	ra,ffffffffc02020ba <free_pages>
    free_page(p2);
ffffffffc0201448:	4585                	li	a1,1
ffffffffc020144a:	8562                	mv	a0,s8
ffffffffc020144c:	46f000ef          	jal	ra,ffffffffc02020ba <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201450:	4515                	li	a0,5
ffffffffc0201452:	42b000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc0201456:	89aa                	mv	s3,a0
ffffffffc0201458:	48050263          	beqz	a0,ffffffffc02018dc <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc020145c:	4505                	li	a0,1
ffffffffc020145e:	41f000ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc0201462:	2c051d63          	bnez	a0,ffffffffc020173c <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201466:	481c                	lw	a5,16(s0)
ffffffffc0201468:	2a079a63          	bnez	a5,ffffffffc020171c <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020146c:	4595                	li	a1,5
ffffffffc020146e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201470:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201474:	01643023          	sd	s6,0(s0)
ffffffffc0201478:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020147c:	43f000ef          	jal	ra,ffffffffc02020ba <free_pages>
    return listelm->next;
ffffffffc0201480:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201482:	00878963          	beq	a5,s0,ffffffffc0201494 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201486:	ff87a703          	lw	a4,-8(a5)
ffffffffc020148a:	679c                	ld	a5,8(a5)
ffffffffc020148c:	397d                	addiw	s2,s2,-1
ffffffffc020148e:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201490:	fe879be3          	bne	a5,s0,ffffffffc0201486 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201494:	26091463          	bnez	s2,ffffffffc02016fc <default_check+0x522>
    assert(total == 0);
ffffffffc0201498:	46049263          	bnez	s1,ffffffffc02018fc <default_check+0x722>
}
ffffffffc020149c:	60a6                	ld	ra,72(sp)
ffffffffc020149e:	6406                	ld	s0,64(sp)
ffffffffc02014a0:	74e2                	ld	s1,56(sp)
ffffffffc02014a2:	7942                	ld	s2,48(sp)
ffffffffc02014a4:	79a2                	ld	s3,40(sp)
ffffffffc02014a6:	7a02                	ld	s4,32(sp)
ffffffffc02014a8:	6ae2                	ld	s5,24(sp)
ffffffffc02014aa:	6b42                	ld	s6,16(sp)
ffffffffc02014ac:	6ba2                	ld	s7,8(sp)
ffffffffc02014ae:	6c02                	ld	s8,0(sp)
ffffffffc02014b0:	6161                	addi	sp,sp,80
ffffffffc02014b2:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02014b4:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02014b6:	4481                	li	s1,0
ffffffffc02014b8:	4901                	li	s2,0
ffffffffc02014ba:	b38d                	j	ffffffffc020121c <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02014bc:	00005697          	auipc	a3,0x5
ffffffffc02014c0:	f3c68693          	addi	a3,a3,-196 # ffffffffc02063f8 <commands+0x8d8>
ffffffffc02014c4:	00005617          	auipc	a2,0x5
ffffffffc02014c8:	f4460613          	addi	a2,a2,-188 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02014cc:	11000593          	li	a1,272
ffffffffc02014d0:	00005517          	auipc	a0,0x5
ffffffffc02014d4:	f5050513          	addi	a0,a0,-176 # ffffffffc0206420 <commands+0x900>
ffffffffc02014d8:	fb7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02014dc:	00005697          	auipc	a3,0x5
ffffffffc02014e0:	fdc68693          	addi	a3,a3,-36 # ffffffffc02064b8 <commands+0x998>
ffffffffc02014e4:	00005617          	auipc	a2,0x5
ffffffffc02014e8:	f2460613          	addi	a2,a2,-220 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02014ec:	0db00593          	li	a1,219
ffffffffc02014f0:	00005517          	auipc	a0,0x5
ffffffffc02014f4:	f3050513          	addi	a0,a0,-208 # ffffffffc0206420 <commands+0x900>
ffffffffc02014f8:	f97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02014fc:	00005697          	auipc	a3,0x5
ffffffffc0201500:	fe468693          	addi	a3,a3,-28 # ffffffffc02064e0 <commands+0x9c0>
ffffffffc0201504:	00005617          	auipc	a2,0x5
ffffffffc0201508:	f0460613          	addi	a2,a2,-252 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020150c:	0dc00593          	li	a1,220
ffffffffc0201510:	00005517          	auipc	a0,0x5
ffffffffc0201514:	f1050513          	addi	a0,a0,-240 # ffffffffc0206420 <commands+0x900>
ffffffffc0201518:	f77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020151c:	00005697          	auipc	a3,0x5
ffffffffc0201520:	00468693          	addi	a3,a3,4 # ffffffffc0206520 <commands+0xa00>
ffffffffc0201524:	00005617          	auipc	a2,0x5
ffffffffc0201528:	ee460613          	addi	a2,a2,-284 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020152c:	0de00593          	li	a1,222
ffffffffc0201530:	00005517          	auipc	a0,0x5
ffffffffc0201534:	ef050513          	addi	a0,a0,-272 # ffffffffc0206420 <commands+0x900>
ffffffffc0201538:	f57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc020153c:	00005697          	auipc	a3,0x5
ffffffffc0201540:	06c68693          	addi	a3,a3,108 # ffffffffc02065a8 <commands+0xa88>
ffffffffc0201544:	00005617          	auipc	a2,0x5
ffffffffc0201548:	ec460613          	addi	a2,a2,-316 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020154c:	0f700593          	li	a1,247
ffffffffc0201550:	00005517          	auipc	a0,0x5
ffffffffc0201554:	ed050513          	addi	a0,a0,-304 # ffffffffc0206420 <commands+0x900>
ffffffffc0201558:	f37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020155c:	00005697          	auipc	a3,0x5
ffffffffc0201560:	efc68693          	addi	a3,a3,-260 # ffffffffc0206458 <commands+0x938>
ffffffffc0201564:	00005617          	auipc	a2,0x5
ffffffffc0201568:	ea460613          	addi	a2,a2,-348 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020156c:	0f000593          	li	a1,240
ffffffffc0201570:	00005517          	auipc	a0,0x5
ffffffffc0201574:	eb050513          	addi	a0,a0,-336 # ffffffffc0206420 <commands+0x900>
ffffffffc0201578:	f17fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc020157c:	00005697          	auipc	a3,0x5
ffffffffc0201580:	01c68693          	addi	a3,a3,28 # ffffffffc0206598 <commands+0xa78>
ffffffffc0201584:	00005617          	auipc	a2,0x5
ffffffffc0201588:	e8460613          	addi	a2,a2,-380 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020158c:	0ee00593          	li	a1,238
ffffffffc0201590:	00005517          	auipc	a0,0x5
ffffffffc0201594:	e9050513          	addi	a0,a0,-368 # ffffffffc0206420 <commands+0x900>
ffffffffc0201598:	ef7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020159c:	00005697          	auipc	a3,0x5
ffffffffc02015a0:	fe468693          	addi	a3,a3,-28 # ffffffffc0206580 <commands+0xa60>
ffffffffc02015a4:	00005617          	auipc	a2,0x5
ffffffffc02015a8:	e6460613          	addi	a2,a2,-412 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02015ac:	0e900593          	li	a1,233
ffffffffc02015b0:	00005517          	auipc	a0,0x5
ffffffffc02015b4:	e7050513          	addi	a0,a0,-400 # ffffffffc0206420 <commands+0x900>
ffffffffc02015b8:	ed7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02015bc:	00005697          	auipc	a3,0x5
ffffffffc02015c0:	fa468693          	addi	a3,a3,-92 # ffffffffc0206560 <commands+0xa40>
ffffffffc02015c4:	00005617          	auipc	a2,0x5
ffffffffc02015c8:	e4460613          	addi	a2,a2,-444 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02015cc:	0e000593          	li	a1,224
ffffffffc02015d0:	00005517          	auipc	a0,0x5
ffffffffc02015d4:	e5050513          	addi	a0,a0,-432 # ffffffffc0206420 <commands+0x900>
ffffffffc02015d8:	eb7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc02015dc:	00005697          	auipc	a3,0x5
ffffffffc02015e0:	01468693          	addi	a3,a3,20 # ffffffffc02065f0 <commands+0xad0>
ffffffffc02015e4:	00005617          	auipc	a2,0x5
ffffffffc02015e8:	e2460613          	addi	a2,a2,-476 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02015ec:	11800593          	li	a1,280
ffffffffc02015f0:	00005517          	auipc	a0,0x5
ffffffffc02015f4:	e3050513          	addi	a0,a0,-464 # ffffffffc0206420 <commands+0x900>
ffffffffc02015f8:	e97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02015fc:	00005697          	auipc	a3,0x5
ffffffffc0201600:	fe468693          	addi	a3,a3,-28 # ffffffffc02065e0 <commands+0xac0>
ffffffffc0201604:	00005617          	auipc	a2,0x5
ffffffffc0201608:	e0460613          	addi	a2,a2,-508 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020160c:	0fd00593          	li	a1,253
ffffffffc0201610:	00005517          	auipc	a0,0x5
ffffffffc0201614:	e1050513          	addi	a0,a0,-496 # ffffffffc0206420 <commands+0x900>
ffffffffc0201618:	e77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020161c:	00005697          	auipc	a3,0x5
ffffffffc0201620:	f6468693          	addi	a3,a3,-156 # ffffffffc0206580 <commands+0xa60>
ffffffffc0201624:	00005617          	auipc	a2,0x5
ffffffffc0201628:	de460613          	addi	a2,a2,-540 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020162c:	0fb00593          	li	a1,251
ffffffffc0201630:	00005517          	auipc	a0,0x5
ffffffffc0201634:	df050513          	addi	a0,a0,-528 # ffffffffc0206420 <commands+0x900>
ffffffffc0201638:	e57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020163c:	00005697          	auipc	a3,0x5
ffffffffc0201640:	f8468693          	addi	a3,a3,-124 # ffffffffc02065c0 <commands+0xaa0>
ffffffffc0201644:	00005617          	auipc	a2,0x5
ffffffffc0201648:	dc460613          	addi	a2,a2,-572 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020164c:	0fa00593          	li	a1,250
ffffffffc0201650:	00005517          	auipc	a0,0x5
ffffffffc0201654:	dd050513          	addi	a0,a0,-560 # ffffffffc0206420 <commands+0x900>
ffffffffc0201658:	e37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020165c:	00005697          	auipc	a3,0x5
ffffffffc0201660:	dfc68693          	addi	a3,a3,-516 # ffffffffc0206458 <commands+0x938>
ffffffffc0201664:	00005617          	auipc	a2,0x5
ffffffffc0201668:	da460613          	addi	a2,a2,-604 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020166c:	0d700593          	li	a1,215
ffffffffc0201670:	00005517          	auipc	a0,0x5
ffffffffc0201674:	db050513          	addi	a0,a0,-592 # ffffffffc0206420 <commands+0x900>
ffffffffc0201678:	e17fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020167c:	00005697          	auipc	a3,0x5
ffffffffc0201680:	f0468693          	addi	a3,a3,-252 # ffffffffc0206580 <commands+0xa60>
ffffffffc0201684:	00005617          	auipc	a2,0x5
ffffffffc0201688:	d8460613          	addi	a2,a2,-636 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020168c:	0f400593          	li	a1,244
ffffffffc0201690:	00005517          	auipc	a0,0x5
ffffffffc0201694:	d9050513          	addi	a0,a0,-624 # ffffffffc0206420 <commands+0x900>
ffffffffc0201698:	df7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020169c:	00005697          	auipc	a3,0x5
ffffffffc02016a0:	dfc68693          	addi	a3,a3,-516 # ffffffffc0206498 <commands+0x978>
ffffffffc02016a4:	00005617          	auipc	a2,0x5
ffffffffc02016a8:	d6460613          	addi	a2,a2,-668 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02016ac:	0f200593          	li	a1,242
ffffffffc02016b0:	00005517          	auipc	a0,0x5
ffffffffc02016b4:	d7050513          	addi	a0,a0,-656 # ffffffffc0206420 <commands+0x900>
ffffffffc02016b8:	dd7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02016bc:	00005697          	auipc	a3,0x5
ffffffffc02016c0:	dbc68693          	addi	a3,a3,-580 # ffffffffc0206478 <commands+0x958>
ffffffffc02016c4:	00005617          	auipc	a2,0x5
ffffffffc02016c8:	d4460613          	addi	a2,a2,-700 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02016cc:	0f100593          	li	a1,241
ffffffffc02016d0:	00005517          	auipc	a0,0x5
ffffffffc02016d4:	d5050513          	addi	a0,a0,-688 # ffffffffc0206420 <commands+0x900>
ffffffffc02016d8:	db7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02016dc:	00005697          	auipc	a3,0x5
ffffffffc02016e0:	dbc68693          	addi	a3,a3,-580 # ffffffffc0206498 <commands+0x978>
ffffffffc02016e4:	00005617          	auipc	a2,0x5
ffffffffc02016e8:	d2460613          	addi	a2,a2,-732 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02016ec:	0d900593          	li	a1,217
ffffffffc02016f0:	00005517          	auipc	a0,0x5
ffffffffc02016f4:	d3050513          	addi	a0,a0,-720 # ffffffffc0206420 <commands+0x900>
ffffffffc02016f8:	d97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc02016fc:	00005697          	auipc	a3,0x5
ffffffffc0201700:	04468693          	addi	a3,a3,68 # ffffffffc0206740 <commands+0xc20>
ffffffffc0201704:	00005617          	auipc	a2,0x5
ffffffffc0201708:	d0460613          	addi	a2,a2,-764 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020170c:	14600593          	li	a1,326
ffffffffc0201710:	00005517          	auipc	a0,0x5
ffffffffc0201714:	d1050513          	addi	a0,a0,-752 # ffffffffc0206420 <commands+0x900>
ffffffffc0201718:	d77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc020171c:	00005697          	auipc	a3,0x5
ffffffffc0201720:	ec468693          	addi	a3,a3,-316 # ffffffffc02065e0 <commands+0xac0>
ffffffffc0201724:	00005617          	auipc	a2,0x5
ffffffffc0201728:	ce460613          	addi	a2,a2,-796 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020172c:	13a00593          	li	a1,314
ffffffffc0201730:	00005517          	auipc	a0,0x5
ffffffffc0201734:	cf050513          	addi	a0,a0,-784 # ffffffffc0206420 <commands+0x900>
ffffffffc0201738:	d57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020173c:	00005697          	auipc	a3,0x5
ffffffffc0201740:	e4468693          	addi	a3,a3,-444 # ffffffffc0206580 <commands+0xa60>
ffffffffc0201744:	00005617          	auipc	a2,0x5
ffffffffc0201748:	cc460613          	addi	a2,a2,-828 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020174c:	13800593          	li	a1,312
ffffffffc0201750:	00005517          	auipc	a0,0x5
ffffffffc0201754:	cd050513          	addi	a0,a0,-816 # ffffffffc0206420 <commands+0x900>
ffffffffc0201758:	d37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020175c:	00005697          	auipc	a3,0x5
ffffffffc0201760:	de468693          	addi	a3,a3,-540 # ffffffffc0206540 <commands+0xa20>
ffffffffc0201764:	00005617          	auipc	a2,0x5
ffffffffc0201768:	ca460613          	addi	a2,a2,-860 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020176c:	0df00593          	li	a1,223
ffffffffc0201770:	00005517          	auipc	a0,0x5
ffffffffc0201774:	cb050513          	addi	a0,a0,-848 # ffffffffc0206420 <commands+0x900>
ffffffffc0201778:	d17fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020177c:	00005697          	auipc	a3,0x5
ffffffffc0201780:	f8468693          	addi	a3,a3,-124 # ffffffffc0206700 <commands+0xbe0>
ffffffffc0201784:	00005617          	auipc	a2,0x5
ffffffffc0201788:	c8460613          	addi	a2,a2,-892 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020178c:	13200593          	li	a1,306
ffffffffc0201790:	00005517          	auipc	a0,0x5
ffffffffc0201794:	c9050513          	addi	a0,a0,-880 # ffffffffc0206420 <commands+0x900>
ffffffffc0201798:	cf7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020179c:	00005697          	auipc	a3,0x5
ffffffffc02017a0:	f4468693          	addi	a3,a3,-188 # ffffffffc02066e0 <commands+0xbc0>
ffffffffc02017a4:	00005617          	auipc	a2,0x5
ffffffffc02017a8:	c6460613          	addi	a2,a2,-924 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02017ac:	13000593          	li	a1,304
ffffffffc02017b0:	00005517          	auipc	a0,0x5
ffffffffc02017b4:	c7050513          	addi	a0,a0,-912 # ffffffffc0206420 <commands+0x900>
ffffffffc02017b8:	cd7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02017bc:	00005697          	auipc	a3,0x5
ffffffffc02017c0:	efc68693          	addi	a3,a3,-260 # ffffffffc02066b8 <commands+0xb98>
ffffffffc02017c4:	00005617          	auipc	a2,0x5
ffffffffc02017c8:	c4460613          	addi	a2,a2,-956 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02017cc:	12e00593          	li	a1,302
ffffffffc02017d0:	00005517          	auipc	a0,0x5
ffffffffc02017d4:	c5050513          	addi	a0,a0,-944 # ffffffffc0206420 <commands+0x900>
ffffffffc02017d8:	cb7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02017dc:	00005697          	auipc	a3,0x5
ffffffffc02017e0:	eb468693          	addi	a3,a3,-332 # ffffffffc0206690 <commands+0xb70>
ffffffffc02017e4:	00005617          	auipc	a2,0x5
ffffffffc02017e8:	c2460613          	addi	a2,a2,-988 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02017ec:	12d00593          	li	a1,301
ffffffffc02017f0:	00005517          	auipc	a0,0x5
ffffffffc02017f4:	c3050513          	addi	a0,a0,-976 # ffffffffc0206420 <commands+0x900>
ffffffffc02017f8:	c97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc02017fc:	00005697          	auipc	a3,0x5
ffffffffc0201800:	e8468693          	addi	a3,a3,-380 # ffffffffc0206680 <commands+0xb60>
ffffffffc0201804:	00005617          	auipc	a2,0x5
ffffffffc0201808:	c0460613          	addi	a2,a2,-1020 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020180c:	12800593          	li	a1,296
ffffffffc0201810:	00005517          	auipc	a0,0x5
ffffffffc0201814:	c1050513          	addi	a0,a0,-1008 # ffffffffc0206420 <commands+0x900>
ffffffffc0201818:	c77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020181c:	00005697          	auipc	a3,0x5
ffffffffc0201820:	d6468693          	addi	a3,a3,-668 # ffffffffc0206580 <commands+0xa60>
ffffffffc0201824:	00005617          	auipc	a2,0x5
ffffffffc0201828:	be460613          	addi	a2,a2,-1052 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020182c:	12700593          	li	a1,295
ffffffffc0201830:	00005517          	auipc	a0,0x5
ffffffffc0201834:	bf050513          	addi	a0,a0,-1040 # ffffffffc0206420 <commands+0x900>
ffffffffc0201838:	c57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020183c:	00005697          	auipc	a3,0x5
ffffffffc0201840:	e2468693          	addi	a3,a3,-476 # ffffffffc0206660 <commands+0xb40>
ffffffffc0201844:	00005617          	auipc	a2,0x5
ffffffffc0201848:	bc460613          	addi	a2,a2,-1084 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020184c:	12600593          	li	a1,294
ffffffffc0201850:	00005517          	auipc	a0,0x5
ffffffffc0201854:	bd050513          	addi	a0,a0,-1072 # ffffffffc0206420 <commands+0x900>
ffffffffc0201858:	c37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020185c:	00005697          	auipc	a3,0x5
ffffffffc0201860:	dd468693          	addi	a3,a3,-556 # ffffffffc0206630 <commands+0xb10>
ffffffffc0201864:	00005617          	auipc	a2,0x5
ffffffffc0201868:	ba460613          	addi	a2,a2,-1116 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020186c:	12500593          	li	a1,293
ffffffffc0201870:	00005517          	auipc	a0,0x5
ffffffffc0201874:	bb050513          	addi	a0,a0,-1104 # ffffffffc0206420 <commands+0x900>
ffffffffc0201878:	c17fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020187c:	00005697          	auipc	a3,0x5
ffffffffc0201880:	d9c68693          	addi	a3,a3,-612 # ffffffffc0206618 <commands+0xaf8>
ffffffffc0201884:	00005617          	auipc	a2,0x5
ffffffffc0201888:	b8460613          	addi	a2,a2,-1148 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020188c:	12400593          	li	a1,292
ffffffffc0201890:	00005517          	auipc	a0,0x5
ffffffffc0201894:	b9050513          	addi	a0,a0,-1136 # ffffffffc0206420 <commands+0x900>
ffffffffc0201898:	bf7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020189c:	00005697          	auipc	a3,0x5
ffffffffc02018a0:	ce468693          	addi	a3,a3,-796 # ffffffffc0206580 <commands+0xa60>
ffffffffc02018a4:	00005617          	auipc	a2,0x5
ffffffffc02018a8:	b6460613          	addi	a2,a2,-1180 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02018ac:	11e00593          	li	a1,286
ffffffffc02018b0:	00005517          	auipc	a0,0x5
ffffffffc02018b4:	b7050513          	addi	a0,a0,-1168 # ffffffffc0206420 <commands+0x900>
ffffffffc02018b8:	bd7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc02018bc:	00005697          	auipc	a3,0x5
ffffffffc02018c0:	d4468693          	addi	a3,a3,-700 # ffffffffc0206600 <commands+0xae0>
ffffffffc02018c4:	00005617          	auipc	a2,0x5
ffffffffc02018c8:	b4460613          	addi	a2,a2,-1212 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02018cc:	11900593          	li	a1,281
ffffffffc02018d0:	00005517          	auipc	a0,0x5
ffffffffc02018d4:	b5050513          	addi	a0,a0,-1200 # ffffffffc0206420 <commands+0x900>
ffffffffc02018d8:	bb7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02018dc:	00005697          	auipc	a3,0x5
ffffffffc02018e0:	e4468693          	addi	a3,a3,-444 # ffffffffc0206720 <commands+0xc00>
ffffffffc02018e4:	00005617          	auipc	a2,0x5
ffffffffc02018e8:	b2460613          	addi	a2,a2,-1244 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02018ec:	13700593          	li	a1,311
ffffffffc02018f0:	00005517          	auipc	a0,0x5
ffffffffc02018f4:	b3050513          	addi	a0,a0,-1232 # ffffffffc0206420 <commands+0x900>
ffffffffc02018f8:	b97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc02018fc:	00005697          	auipc	a3,0x5
ffffffffc0201900:	e5468693          	addi	a3,a3,-428 # ffffffffc0206750 <commands+0xc30>
ffffffffc0201904:	00005617          	auipc	a2,0x5
ffffffffc0201908:	b0460613          	addi	a2,a2,-1276 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020190c:	14700593          	li	a1,327
ffffffffc0201910:	00005517          	auipc	a0,0x5
ffffffffc0201914:	b1050513          	addi	a0,a0,-1264 # ffffffffc0206420 <commands+0x900>
ffffffffc0201918:	b77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc020191c:	00005697          	auipc	a3,0x5
ffffffffc0201920:	b1c68693          	addi	a3,a3,-1252 # ffffffffc0206438 <commands+0x918>
ffffffffc0201924:	00005617          	auipc	a2,0x5
ffffffffc0201928:	ae460613          	addi	a2,a2,-1308 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020192c:	11300593          	li	a1,275
ffffffffc0201930:	00005517          	auipc	a0,0x5
ffffffffc0201934:	af050513          	addi	a0,a0,-1296 # ffffffffc0206420 <commands+0x900>
ffffffffc0201938:	b57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020193c:	00005697          	auipc	a3,0x5
ffffffffc0201940:	b3c68693          	addi	a3,a3,-1220 # ffffffffc0206478 <commands+0x958>
ffffffffc0201944:	00005617          	auipc	a2,0x5
ffffffffc0201948:	ac460613          	addi	a2,a2,-1340 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020194c:	0d800593          	li	a1,216
ffffffffc0201950:	00005517          	auipc	a0,0x5
ffffffffc0201954:	ad050513          	addi	a0,a0,-1328 # ffffffffc0206420 <commands+0x900>
ffffffffc0201958:	b37fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020195c <default_free_pages>:
{
ffffffffc020195c:	1141                	addi	sp,sp,-16
ffffffffc020195e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201960:	14058463          	beqz	a1,ffffffffc0201aa8 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201964:	00659693          	slli	a3,a1,0x6
ffffffffc0201968:	96aa                	add	a3,a3,a0
ffffffffc020196a:	87aa                	mv	a5,a0
ffffffffc020196c:	02d50263          	beq	a0,a3,ffffffffc0201990 <default_free_pages+0x34>
ffffffffc0201970:	6798                	ld	a4,8(a5)
ffffffffc0201972:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201974:	10071a63          	bnez	a4,ffffffffc0201a88 <default_free_pages+0x12c>
ffffffffc0201978:	6798                	ld	a4,8(a5)
ffffffffc020197a:	8b09                	andi	a4,a4,2
ffffffffc020197c:	10071663          	bnez	a4,ffffffffc0201a88 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201980:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201984:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201988:	04078793          	addi	a5,a5,64
ffffffffc020198c:	fed792e3          	bne	a5,a3,ffffffffc0201970 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201990:	2581                	sext.w	a1,a1
ffffffffc0201992:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201994:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201998:	4789                	li	a5,2
ffffffffc020199a:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020199e:	000a5697          	auipc	a3,0xa5
ffffffffc02019a2:	d0268693          	addi	a3,a3,-766 # ffffffffc02a66a0 <free_area>
ffffffffc02019a6:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02019a8:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02019aa:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02019ae:	9db9                	addw	a1,a1,a4
ffffffffc02019b0:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02019b2:	0ad78463          	beq	a5,a3,ffffffffc0201a5a <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc02019b6:	fe878713          	addi	a4,a5,-24
ffffffffc02019ba:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02019be:	4581                	li	a1,0
            if (base < page)
ffffffffc02019c0:	00e56a63          	bltu	a0,a4,ffffffffc02019d4 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02019c4:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02019c6:	04d70c63          	beq	a4,a3,ffffffffc0201a1e <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc02019ca:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02019cc:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02019d0:	fee57ae3          	bgeu	a0,a4,ffffffffc02019c4 <default_free_pages+0x68>
ffffffffc02019d4:	c199                	beqz	a1,ffffffffc02019da <default_free_pages+0x7e>
ffffffffc02019d6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02019da:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02019dc:	e390                	sd	a2,0(a5)
ffffffffc02019de:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02019e0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02019e2:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02019e4:	00d70d63          	beq	a4,a3,ffffffffc02019fe <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02019e8:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02019ec:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02019f0:	02059813          	slli	a6,a1,0x20
ffffffffc02019f4:	01a85793          	srli	a5,a6,0x1a
ffffffffc02019f8:	97b2                	add	a5,a5,a2
ffffffffc02019fa:	02f50c63          	beq	a0,a5,ffffffffc0201a32 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02019fe:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201a00:	00d78c63          	beq	a5,a3,ffffffffc0201a18 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201a04:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201a06:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc0201a0a:	02061593          	slli	a1,a2,0x20
ffffffffc0201a0e:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201a12:	972a                	add	a4,a4,a0
ffffffffc0201a14:	04e68a63          	beq	a3,a4,ffffffffc0201a68 <default_free_pages+0x10c>
}
ffffffffc0201a18:	60a2                	ld	ra,8(sp)
ffffffffc0201a1a:	0141                	addi	sp,sp,16
ffffffffc0201a1c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201a1e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a20:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201a22:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201a24:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a26:	02d70763          	beq	a4,a3,ffffffffc0201a54 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0201a2a:	8832                	mv	a6,a2
ffffffffc0201a2c:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201a2e:	87ba                	mv	a5,a4
ffffffffc0201a30:	bf71                	j	ffffffffc02019cc <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201a32:	491c                	lw	a5,16(a0)
ffffffffc0201a34:	9dbd                	addw	a1,a1,a5
ffffffffc0201a36:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201a3a:	57f5                	li	a5,-3
ffffffffc0201a3c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201a40:	01853803          	ld	a6,24(a0)
ffffffffc0201a44:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201a46:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201a48:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201a4c:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201a4e:	0105b023          	sd	a6,0(a1)
ffffffffc0201a52:	b77d                	j	ffffffffc0201a00 <default_free_pages+0xa4>
ffffffffc0201a54:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a56:	873e                	mv	a4,a5
ffffffffc0201a58:	bf41                	j	ffffffffc02019e8 <default_free_pages+0x8c>
}
ffffffffc0201a5a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201a5c:	e390                	sd	a2,0(a5)
ffffffffc0201a5e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a60:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a62:	ed1c                	sd	a5,24(a0)
ffffffffc0201a64:	0141                	addi	sp,sp,16
ffffffffc0201a66:	8082                	ret
            base->property += p->property;
ffffffffc0201a68:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201a6c:	ff078693          	addi	a3,a5,-16
ffffffffc0201a70:	9e39                	addw	a2,a2,a4
ffffffffc0201a72:	c910                	sw	a2,16(a0)
ffffffffc0201a74:	5775                	li	a4,-3
ffffffffc0201a76:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201a7a:	6398                	ld	a4,0(a5)
ffffffffc0201a7c:	679c                	ld	a5,8(a5)
}
ffffffffc0201a7e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201a80:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201a82:	e398                	sd	a4,0(a5)
ffffffffc0201a84:	0141                	addi	sp,sp,16
ffffffffc0201a86:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201a88:	00005697          	auipc	a3,0x5
ffffffffc0201a8c:	ce068693          	addi	a3,a3,-800 # ffffffffc0206768 <commands+0xc48>
ffffffffc0201a90:	00005617          	auipc	a2,0x5
ffffffffc0201a94:	97860613          	addi	a2,a2,-1672 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0201a98:	09400593          	li	a1,148
ffffffffc0201a9c:	00005517          	auipc	a0,0x5
ffffffffc0201aa0:	98450513          	addi	a0,a0,-1660 # ffffffffc0206420 <commands+0x900>
ffffffffc0201aa4:	9ebfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201aa8:	00005697          	auipc	a3,0x5
ffffffffc0201aac:	cb868693          	addi	a3,a3,-840 # ffffffffc0206760 <commands+0xc40>
ffffffffc0201ab0:	00005617          	auipc	a2,0x5
ffffffffc0201ab4:	95860613          	addi	a2,a2,-1704 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0201ab8:	09000593          	li	a1,144
ffffffffc0201abc:	00005517          	auipc	a0,0x5
ffffffffc0201ac0:	96450513          	addi	a0,a0,-1692 # ffffffffc0206420 <commands+0x900>
ffffffffc0201ac4:	9cbfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ac8 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201ac8:	c941                	beqz	a0,ffffffffc0201b58 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc0201aca:	000a5597          	auipc	a1,0xa5
ffffffffc0201ace:	bd658593          	addi	a1,a1,-1066 # ffffffffc02a66a0 <free_area>
ffffffffc0201ad2:	0105a803          	lw	a6,16(a1)
ffffffffc0201ad6:	872a                	mv	a4,a0
ffffffffc0201ad8:	02081793          	slli	a5,a6,0x20
ffffffffc0201adc:	9381                	srli	a5,a5,0x20
ffffffffc0201ade:	00a7ee63          	bltu	a5,a0,ffffffffc0201afa <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201ae2:	87ae                	mv	a5,a1
ffffffffc0201ae4:	a801                	j	ffffffffc0201af4 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0201ae6:	ff87a683          	lw	a3,-8(a5)
ffffffffc0201aea:	02069613          	slli	a2,a3,0x20
ffffffffc0201aee:	9201                	srli	a2,a2,0x20
ffffffffc0201af0:	00e67763          	bgeu	a2,a4,ffffffffc0201afe <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201af4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201af6:	feb798e3          	bne	a5,a1,ffffffffc0201ae6 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201afa:	4501                	li	a0,0
}
ffffffffc0201afc:	8082                	ret
    return listelm->prev;
ffffffffc0201afe:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201b02:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201b06:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201b0a:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0201b0e:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201b12:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0201b16:	02c77863          	bgeu	a4,a2,ffffffffc0201b46 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201b1a:	071a                	slli	a4,a4,0x6
ffffffffc0201b1c:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201b1e:	41c686bb          	subw	a3,a3,t3
ffffffffc0201b22:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201b24:	00870613          	addi	a2,a4,8
ffffffffc0201b28:	4689                	li	a3,2
ffffffffc0201b2a:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201b2e:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201b32:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201b36:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201b3a:	e290                	sd	a2,0(a3)
ffffffffc0201b3c:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201b40:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201b42:	01173c23          	sd	a7,24(a4)
ffffffffc0201b46:	41c8083b          	subw	a6,a6,t3
ffffffffc0201b4a:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201b4e:	5775                	li	a4,-3
ffffffffc0201b50:	17c1                	addi	a5,a5,-16
ffffffffc0201b52:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201b56:	8082                	ret
{
ffffffffc0201b58:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201b5a:	00005697          	auipc	a3,0x5
ffffffffc0201b5e:	c0668693          	addi	a3,a3,-1018 # ffffffffc0206760 <commands+0xc40>
ffffffffc0201b62:	00005617          	auipc	a2,0x5
ffffffffc0201b66:	8a660613          	addi	a2,a2,-1882 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0201b6a:	06c00593          	li	a1,108
ffffffffc0201b6e:	00005517          	auipc	a0,0x5
ffffffffc0201b72:	8b250513          	addi	a0,a0,-1870 # ffffffffc0206420 <commands+0x900>
{
ffffffffc0201b76:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201b78:	917fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201b7c <default_init_memmap>:
{
ffffffffc0201b7c:	1141                	addi	sp,sp,-16
ffffffffc0201b7e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201b80:	c5f1                	beqz	a1,ffffffffc0201c4c <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201b82:	00659693          	slli	a3,a1,0x6
ffffffffc0201b86:	96aa                	add	a3,a3,a0
ffffffffc0201b88:	87aa                	mv	a5,a0
ffffffffc0201b8a:	00d50f63          	beq	a0,a3,ffffffffc0201ba8 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201b8e:	6798                	ld	a4,8(a5)
ffffffffc0201b90:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201b92:	cf49                	beqz	a4,ffffffffc0201c2c <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201b94:	0007a823          	sw	zero,16(a5)
ffffffffc0201b98:	0007b423          	sd	zero,8(a5)
ffffffffc0201b9c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201ba0:	04078793          	addi	a5,a5,64
ffffffffc0201ba4:	fed795e3          	bne	a5,a3,ffffffffc0201b8e <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201ba8:	2581                	sext.w	a1,a1
ffffffffc0201baa:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201bac:	4789                	li	a5,2
ffffffffc0201bae:	00850713          	addi	a4,a0,8
ffffffffc0201bb2:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201bb6:	000a5697          	auipc	a3,0xa5
ffffffffc0201bba:	aea68693          	addi	a3,a3,-1302 # ffffffffc02a66a0 <free_area>
ffffffffc0201bbe:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201bc0:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201bc2:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201bc6:	9db9                	addw	a1,a1,a4
ffffffffc0201bc8:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201bca:	04d78a63          	beq	a5,a3,ffffffffc0201c1e <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201bce:	fe878713          	addi	a4,a5,-24
ffffffffc0201bd2:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201bd6:	4581                	li	a1,0
            if (base < page)
ffffffffc0201bd8:	00e56a63          	bltu	a0,a4,ffffffffc0201bec <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201bdc:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201bde:	02d70263          	beq	a4,a3,ffffffffc0201c02 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0201be2:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201be4:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201be8:	fee57ae3          	bgeu	a0,a4,ffffffffc0201bdc <default_init_memmap+0x60>
ffffffffc0201bec:	c199                	beqz	a1,ffffffffc0201bf2 <default_init_memmap+0x76>
ffffffffc0201bee:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201bf2:	6398                	ld	a4,0(a5)
}
ffffffffc0201bf4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201bf6:	e390                	sd	a2,0(a5)
ffffffffc0201bf8:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201bfa:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201bfc:	ed18                	sd	a4,24(a0)
ffffffffc0201bfe:	0141                	addi	sp,sp,16
ffffffffc0201c00:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201c02:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201c04:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201c06:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201c08:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201c0a:	00d70663          	beq	a4,a3,ffffffffc0201c16 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201c0e:	8832                	mv	a6,a2
ffffffffc0201c10:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201c12:	87ba                	mv	a5,a4
ffffffffc0201c14:	bfc1                	j	ffffffffc0201be4 <default_init_memmap+0x68>
}
ffffffffc0201c16:	60a2                	ld	ra,8(sp)
ffffffffc0201c18:	e290                	sd	a2,0(a3)
ffffffffc0201c1a:	0141                	addi	sp,sp,16
ffffffffc0201c1c:	8082                	ret
ffffffffc0201c1e:	60a2                	ld	ra,8(sp)
ffffffffc0201c20:	e390                	sd	a2,0(a5)
ffffffffc0201c22:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201c24:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201c26:	ed1c                	sd	a5,24(a0)
ffffffffc0201c28:	0141                	addi	sp,sp,16
ffffffffc0201c2a:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201c2c:	00005697          	auipc	a3,0x5
ffffffffc0201c30:	b6468693          	addi	a3,a3,-1180 # ffffffffc0206790 <commands+0xc70>
ffffffffc0201c34:	00004617          	auipc	a2,0x4
ffffffffc0201c38:	7d460613          	addi	a2,a2,2004 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0201c3c:	04b00593          	li	a1,75
ffffffffc0201c40:	00004517          	auipc	a0,0x4
ffffffffc0201c44:	7e050513          	addi	a0,a0,2016 # ffffffffc0206420 <commands+0x900>
ffffffffc0201c48:	847fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201c4c:	00005697          	auipc	a3,0x5
ffffffffc0201c50:	b1468693          	addi	a3,a3,-1260 # ffffffffc0206760 <commands+0xc40>
ffffffffc0201c54:	00004617          	auipc	a2,0x4
ffffffffc0201c58:	7b460613          	addi	a2,a2,1972 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0201c5c:	04700593          	li	a1,71
ffffffffc0201c60:	00004517          	auipc	a0,0x4
ffffffffc0201c64:	7c050513          	addi	a0,a0,1984 # ffffffffc0206420 <commands+0x900>
ffffffffc0201c68:	827fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201c6c <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201c6c:	c94d                	beqz	a0,ffffffffc0201d1e <slob_free+0xb2>
{
ffffffffc0201c6e:	1141                	addi	sp,sp,-16
ffffffffc0201c70:	e022                	sd	s0,0(sp)
ffffffffc0201c72:	e406                	sd	ra,8(sp)
ffffffffc0201c74:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201c76:	e9c1                	bnez	a1,ffffffffc0201d06 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c78:	100027f3          	csrr	a5,sstatus
ffffffffc0201c7c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201c7e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c80:	ebd9                	bnez	a5,ffffffffc0201d16 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201c82:	000a4617          	auipc	a2,0xa4
ffffffffc0201c86:	60e60613          	addi	a2,a2,1550 # ffffffffc02a6290 <slobfree>
ffffffffc0201c8a:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201c8c:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201c8e:	679c                	ld	a5,8(a5)
ffffffffc0201c90:	02877a63          	bgeu	a4,s0,ffffffffc0201cc4 <slob_free+0x58>
ffffffffc0201c94:	00f46463          	bltu	s0,a5,ffffffffc0201c9c <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201c98:	fef76ae3          	bltu	a4,a5,ffffffffc0201c8c <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201c9c:	400c                	lw	a1,0(s0)
ffffffffc0201c9e:	00459693          	slli	a3,a1,0x4
ffffffffc0201ca2:	96a2                	add	a3,a3,s0
ffffffffc0201ca4:	02d78a63          	beq	a5,a3,ffffffffc0201cd8 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201ca8:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201caa:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201cac:	00469793          	slli	a5,a3,0x4
ffffffffc0201cb0:	97ba                	add	a5,a5,a4
ffffffffc0201cb2:	02f40e63          	beq	s0,a5,ffffffffc0201cee <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201cb6:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201cb8:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201cba:	e129                	bnez	a0,ffffffffc0201cfc <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201cbc:	60a2                	ld	ra,8(sp)
ffffffffc0201cbe:	6402                	ld	s0,0(sp)
ffffffffc0201cc0:	0141                	addi	sp,sp,16
ffffffffc0201cc2:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201cc4:	fcf764e3          	bltu	a4,a5,ffffffffc0201c8c <slob_free+0x20>
ffffffffc0201cc8:	fcf472e3          	bgeu	s0,a5,ffffffffc0201c8c <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201ccc:	400c                	lw	a1,0(s0)
ffffffffc0201cce:	00459693          	slli	a3,a1,0x4
ffffffffc0201cd2:	96a2                	add	a3,a3,s0
ffffffffc0201cd4:	fcd79ae3          	bne	a5,a3,ffffffffc0201ca8 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201cd8:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201cda:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201cdc:	9db5                	addw	a1,a1,a3
ffffffffc0201cde:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201ce0:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201ce2:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201ce4:	00469793          	slli	a5,a3,0x4
ffffffffc0201ce8:	97ba                	add	a5,a5,a4
ffffffffc0201cea:	fcf416e3          	bne	s0,a5,ffffffffc0201cb6 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201cee:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201cf0:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201cf2:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201cf4:	9ebd                	addw	a3,a3,a5
ffffffffc0201cf6:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201cf8:	e70c                	sd	a1,8(a4)
ffffffffc0201cfa:	d169                	beqz	a0,ffffffffc0201cbc <slob_free+0x50>
}
ffffffffc0201cfc:	6402                	ld	s0,0(sp)
ffffffffc0201cfe:	60a2                	ld	ra,8(sp)
ffffffffc0201d00:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201d02:	cadfe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201d06:	25bd                	addiw	a1,a1,15
ffffffffc0201d08:	8191                	srli	a1,a1,0x4
ffffffffc0201d0a:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d0c:	100027f3          	csrr	a5,sstatus
ffffffffc0201d10:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201d12:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d14:	d7bd                	beqz	a5,ffffffffc0201c82 <slob_free+0x16>
        intr_disable();
ffffffffc0201d16:	c9ffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201d1a:	4505                	li	a0,1
ffffffffc0201d1c:	b79d                	j	ffffffffc0201c82 <slob_free+0x16>
ffffffffc0201d1e:	8082                	ret

ffffffffc0201d20 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201d20:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201d22:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201d24:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201d28:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201d2a:	352000ef          	jal	ra,ffffffffc020207c <alloc_pages>
	if (!page)
ffffffffc0201d2e:	c91d                	beqz	a0,ffffffffc0201d64 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201d30:	000a9697          	auipc	a3,0xa9
ffffffffc0201d34:	9e06b683          	ld	a3,-1568(a3) # ffffffffc02aa710 <pages>
ffffffffc0201d38:	8d15                	sub	a0,a0,a3
ffffffffc0201d3a:	8519                	srai	a0,a0,0x6
ffffffffc0201d3c:	00006697          	auipc	a3,0x6
ffffffffc0201d40:	ce46b683          	ld	a3,-796(a3) # ffffffffc0207a20 <nbase>
ffffffffc0201d44:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201d46:	00c51793          	slli	a5,a0,0xc
ffffffffc0201d4a:	83b1                	srli	a5,a5,0xc
ffffffffc0201d4c:	000a9717          	auipc	a4,0xa9
ffffffffc0201d50:	9bc73703          	ld	a4,-1604(a4) # ffffffffc02aa708 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201d54:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201d56:	00e7fa63          	bgeu	a5,a4,ffffffffc0201d6a <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201d5a:	000a9697          	auipc	a3,0xa9
ffffffffc0201d5e:	9c66b683          	ld	a3,-1594(a3) # ffffffffc02aa720 <va_pa_offset>
ffffffffc0201d62:	9536                	add	a0,a0,a3
}
ffffffffc0201d64:	60a2                	ld	ra,8(sp)
ffffffffc0201d66:	0141                	addi	sp,sp,16
ffffffffc0201d68:	8082                	ret
ffffffffc0201d6a:	86aa                	mv	a3,a0
ffffffffc0201d6c:	00004617          	auipc	a2,0x4
ffffffffc0201d70:	5d460613          	addi	a2,a2,1492 # ffffffffc0206340 <commands+0x820>
ffffffffc0201d74:	07100593          	li	a1,113
ffffffffc0201d78:	00004517          	auipc	a0,0x4
ffffffffc0201d7c:	58050513          	addi	a0,a0,1408 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc0201d80:	f0efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201d84 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201d84:	1101                	addi	sp,sp,-32
ffffffffc0201d86:	ec06                	sd	ra,24(sp)
ffffffffc0201d88:	e822                	sd	s0,16(sp)
ffffffffc0201d8a:	e426                	sd	s1,8(sp)
ffffffffc0201d8c:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201d8e:	01050713          	addi	a4,a0,16
ffffffffc0201d92:	6785                	lui	a5,0x1
ffffffffc0201d94:	0cf77363          	bgeu	a4,a5,ffffffffc0201e5a <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201d98:	00f50493          	addi	s1,a0,15
ffffffffc0201d9c:	8091                	srli	s1,s1,0x4
ffffffffc0201d9e:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201da0:	10002673          	csrr	a2,sstatus
ffffffffc0201da4:	8a09                	andi	a2,a2,2
ffffffffc0201da6:	e25d                	bnez	a2,ffffffffc0201e4c <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201da8:	000a4917          	auipc	s2,0xa4
ffffffffc0201dac:	4e890913          	addi	s2,s2,1256 # ffffffffc02a6290 <slobfree>
ffffffffc0201db0:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201db4:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201db6:	4398                	lw	a4,0(a5)
ffffffffc0201db8:	08975e63          	bge	a4,s1,ffffffffc0201e54 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201dbc:	00f68b63          	beq	a3,a5,ffffffffc0201dd2 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201dc0:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201dc2:	4018                	lw	a4,0(s0)
ffffffffc0201dc4:	02975a63          	bge	a4,s1,ffffffffc0201df8 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201dc8:	00093683          	ld	a3,0(s2)
ffffffffc0201dcc:	87a2                	mv	a5,s0
ffffffffc0201dce:	fef699e3          	bne	a3,a5,ffffffffc0201dc0 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201dd2:	ee31                	bnez	a2,ffffffffc0201e2e <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201dd4:	4501                	li	a0,0
ffffffffc0201dd6:	f4bff0ef          	jal	ra,ffffffffc0201d20 <__slob_get_free_pages.constprop.0>
ffffffffc0201dda:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201ddc:	cd05                	beqz	a0,ffffffffc0201e14 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201dde:	6585                	lui	a1,0x1
ffffffffc0201de0:	e8dff0ef          	jal	ra,ffffffffc0201c6c <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201de4:	10002673          	csrr	a2,sstatus
ffffffffc0201de8:	8a09                	andi	a2,a2,2
ffffffffc0201dea:	ee05                	bnez	a2,ffffffffc0201e22 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201dec:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201df0:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201df2:	4018                	lw	a4,0(s0)
ffffffffc0201df4:	fc974ae3          	blt	a4,s1,ffffffffc0201dc8 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201df8:	04e48763          	beq	s1,a4,ffffffffc0201e46 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201dfc:	00449693          	slli	a3,s1,0x4
ffffffffc0201e00:	96a2                	add	a3,a3,s0
ffffffffc0201e02:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201e04:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201e06:	9f05                	subw	a4,a4,s1
ffffffffc0201e08:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201e0a:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201e0c:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201e0e:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201e12:	e20d                	bnez	a2,ffffffffc0201e34 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201e14:	60e2                	ld	ra,24(sp)
ffffffffc0201e16:	8522                	mv	a0,s0
ffffffffc0201e18:	6442                	ld	s0,16(sp)
ffffffffc0201e1a:	64a2                	ld	s1,8(sp)
ffffffffc0201e1c:	6902                	ld	s2,0(sp)
ffffffffc0201e1e:	6105                	addi	sp,sp,32
ffffffffc0201e20:	8082                	ret
        intr_disable();
ffffffffc0201e22:	b93fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201e26:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201e2a:	4605                	li	a2,1
ffffffffc0201e2c:	b7d1                	j	ffffffffc0201df0 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201e2e:	b81fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e32:	b74d                	j	ffffffffc0201dd4 <slob_alloc.constprop.0+0x50>
ffffffffc0201e34:	b7bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201e38:	60e2                	ld	ra,24(sp)
ffffffffc0201e3a:	8522                	mv	a0,s0
ffffffffc0201e3c:	6442                	ld	s0,16(sp)
ffffffffc0201e3e:	64a2                	ld	s1,8(sp)
ffffffffc0201e40:	6902                	ld	s2,0(sp)
ffffffffc0201e42:	6105                	addi	sp,sp,32
ffffffffc0201e44:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201e46:	6418                	ld	a4,8(s0)
ffffffffc0201e48:	e798                	sd	a4,8(a5)
ffffffffc0201e4a:	b7d1                	j	ffffffffc0201e0e <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201e4c:	b69fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201e50:	4605                	li	a2,1
ffffffffc0201e52:	bf99                	j	ffffffffc0201da8 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201e54:	843e                	mv	s0,a5
ffffffffc0201e56:	87b6                	mv	a5,a3
ffffffffc0201e58:	b745                	j	ffffffffc0201df8 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201e5a:	00005697          	auipc	a3,0x5
ffffffffc0201e5e:	99668693          	addi	a3,a3,-1642 # ffffffffc02067f0 <default_pmm_manager+0x38>
ffffffffc0201e62:	00004617          	auipc	a2,0x4
ffffffffc0201e66:	5a660613          	addi	a2,a2,1446 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0201e6a:	06300593          	li	a1,99
ffffffffc0201e6e:	00005517          	auipc	a0,0x5
ffffffffc0201e72:	9a250513          	addi	a0,a0,-1630 # ffffffffc0206810 <default_pmm_manager+0x58>
ffffffffc0201e76:	e18fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e7a <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201e7a:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201e7c:	00005517          	auipc	a0,0x5
ffffffffc0201e80:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0206828 <default_pmm_manager+0x70>
{
ffffffffc0201e84:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201e86:	b0efe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201e8a:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201e8c:	00005517          	auipc	a0,0x5
ffffffffc0201e90:	9b450513          	addi	a0,a0,-1612 # ffffffffc0206840 <default_pmm_manager+0x88>
}
ffffffffc0201e94:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201e96:	afefe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201e9a <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201e9a:	4501                	li	a0,0
ffffffffc0201e9c:	8082                	ret

ffffffffc0201e9e <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201e9e:	1101                	addi	sp,sp,-32
ffffffffc0201ea0:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ea2:	6905                	lui	s2,0x1
{
ffffffffc0201ea4:	e822                	sd	s0,16(sp)
ffffffffc0201ea6:	ec06                	sd	ra,24(sp)
ffffffffc0201ea8:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201eaa:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bb9>
{
ffffffffc0201eae:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201eb0:	04a7f963          	bgeu	a5,a0,ffffffffc0201f02 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201eb4:	4561                	li	a0,24
ffffffffc0201eb6:	ecfff0ef          	jal	ra,ffffffffc0201d84 <slob_alloc.constprop.0>
ffffffffc0201eba:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201ebc:	c929                	beqz	a0,ffffffffc0201f0e <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201ebe:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201ec2:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201ec4:	00f95763          	bge	s2,a5,ffffffffc0201ed2 <kmalloc+0x34>
ffffffffc0201ec8:	6705                	lui	a4,0x1
ffffffffc0201eca:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201ecc:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201ece:	fef74ee3          	blt	a4,a5,ffffffffc0201eca <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201ed2:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201ed4:	e4dff0ef          	jal	ra,ffffffffc0201d20 <__slob_get_free_pages.constprop.0>
ffffffffc0201ed8:	e488                	sd	a0,8(s1)
ffffffffc0201eda:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201edc:	c525                	beqz	a0,ffffffffc0201f44 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ede:	100027f3          	csrr	a5,sstatus
ffffffffc0201ee2:	8b89                	andi	a5,a5,2
ffffffffc0201ee4:	ef8d                	bnez	a5,ffffffffc0201f1e <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201ee6:	000a9797          	auipc	a5,0xa9
ffffffffc0201eea:	80a78793          	addi	a5,a5,-2038 # ffffffffc02aa6f0 <bigblocks>
ffffffffc0201eee:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201ef0:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201ef2:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201ef4:	60e2                	ld	ra,24(sp)
ffffffffc0201ef6:	8522                	mv	a0,s0
ffffffffc0201ef8:	6442                	ld	s0,16(sp)
ffffffffc0201efa:	64a2                	ld	s1,8(sp)
ffffffffc0201efc:	6902                	ld	s2,0(sp)
ffffffffc0201efe:	6105                	addi	sp,sp,32
ffffffffc0201f00:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201f02:	0541                	addi	a0,a0,16
ffffffffc0201f04:	e81ff0ef          	jal	ra,ffffffffc0201d84 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201f08:	01050413          	addi	s0,a0,16
ffffffffc0201f0c:	f565                	bnez	a0,ffffffffc0201ef4 <kmalloc+0x56>
ffffffffc0201f0e:	4401                	li	s0,0
}
ffffffffc0201f10:	60e2                	ld	ra,24(sp)
ffffffffc0201f12:	8522                	mv	a0,s0
ffffffffc0201f14:	6442                	ld	s0,16(sp)
ffffffffc0201f16:	64a2                	ld	s1,8(sp)
ffffffffc0201f18:	6902                	ld	s2,0(sp)
ffffffffc0201f1a:	6105                	addi	sp,sp,32
ffffffffc0201f1c:	8082                	ret
        intr_disable();
ffffffffc0201f1e:	a97fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201f22:	000a8797          	auipc	a5,0xa8
ffffffffc0201f26:	7ce78793          	addi	a5,a5,1998 # ffffffffc02aa6f0 <bigblocks>
ffffffffc0201f2a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201f2c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201f2e:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201f30:	a7ffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201f34:	6480                	ld	s0,8(s1)
}
ffffffffc0201f36:	60e2                	ld	ra,24(sp)
ffffffffc0201f38:	64a2                	ld	s1,8(sp)
ffffffffc0201f3a:	8522                	mv	a0,s0
ffffffffc0201f3c:	6442                	ld	s0,16(sp)
ffffffffc0201f3e:	6902                	ld	s2,0(sp)
ffffffffc0201f40:	6105                	addi	sp,sp,32
ffffffffc0201f42:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201f44:	45e1                	li	a1,24
ffffffffc0201f46:	8526                	mv	a0,s1
ffffffffc0201f48:	d25ff0ef          	jal	ra,ffffffffc0201c6c <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201f4c:	b765                	j	ffffffffc0201ef4 <kmalloc+0x56>

ffffffffc0201f4e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201f4e:	c169                	beqz	a0,ffffffffc0202010 <kfree+0xc2>
{
ffffffffc0201f50:	1101                	addi	sp,sp,-32
ffffffffc0201f52:	e822                	sd	s0,16(sp)
ffffffffc0201f54:	ec06                	sd	ra,24(sp)
ffffffffc0201f56:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201f58:	03451793          	slli	a5,a0,0x34
ffffffffc0201f5c:	842a                	mv	s0,a0
ffffffffc0201f5e:	e3d9                	bnez	a5,ffffffffc0201fe4 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f60:	100027f3          	csrr	a5,sstatus
ffffffffc0201f64:	8b89                	andi	a5,a5,2
ffffffffc0201f66:	e7d9                	bnez	a5,ffffffffc0201ff4 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201f68:	000a8797          	auipc	a5,0xa8
ffffffffc0201f6c:	7887b783          	ld	a5,1928(a5) # ffffffffc02aa6f0 <bigblocks>
    return 0;
ffffffffc0201f70:	4601                	li	a2,0
ffffffffc0201f72:	cbad                	beqz	a5,ffffffffc0201fe4 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201f74:	000a8697          	auipc	a3,0xa8
ffffffffc0201f78:	77c68693          	addi	a3,a3,1916 # ffffffffc02aa6f0 <bigblocks>
ffffffffc0201f7c:	a021                	j	ffffffffc0201f84 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201f7e:	01048693          	addi	a3,s1,16
ffffffffc0201f82:	c3a5                	beqz	a5,ffffffffc0201fe2 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201f84:	6798                	ld	a4,8(a5)
ffffffffc0201f86:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201f88:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201f8a:	fe871ae3          	bne	a4,s0,ffffffffc0201f7e <kfree+0x30>
				*last = bb->next;
ffffffffc0201f8e:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201f90:	ee2d                	bnez	a2,ffffffffc020200a <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201f92:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201f96:	4098                	lw	a4,0(s1)
ffffffffc0201f98:	08f46963          	bltu	s0,a5,ffffffffc020202a <kfree+0xdc>
ffffffffc0201f9c:	000a8697          	auipc	a3,0xa8
ffffffffc0201fa0:	7846b683          	ld	a3,1924(a3) # ffffffffc02aa720 <va_pa_offset>
ffffffffc0201fa4:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201fa6:	8031                	srli	s0,s0,0xc
ffffffffc0201fa8:	000a8797          	auipc	a5,0xa8
ffffffffc0201fac:	7607b783          	ld	a5,1888(a5) # ffffffffc02aa708 <npage>
ffffffffc0201fb0:	06f47163          	bgeu	s0,a5,ffffffffc0202012 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201fb4:	00006517          	auipc	a0,0x6
ffffffffc0201fb8:	a6c53503          	ld	a0,-1428(a0) # ffffffffc0207a20 <nbase>
ffffffffc0201fbc:	8c09                	sub	s0,s0,a0
ffffffffc0201fbe:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201fc0:	000a8517          	auipc	a0,0xa8
ffffffffc0201fc4:	75053503          	ld	a0,1872(a0) # ffffffffc02aa710 <pages>
ffffffffc0201fc8:	4585                	li	a1,1
ffffffffc0201fca:	9522                	add	a0,a0,s0
ffffffffc0201fcc:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201fd0:	0ea000ef          	jal	ra,ffffffffc02020ba <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201fd4:	6442                	ld	s0,16(sp)
ffffffffc0201fd6:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201fd8:	8526                	mv	a0,s1
}
ffffffffc0201fda:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201fdc:	45e1                	li	a1,24
}
ffffffffc0201fde:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201fe0:	b171                	j	ffffffffc0201c6c <slob_free>
ffffffffc0201fe2:	e20d                	bnez	a2,ffffffffc0202004 <kfree+0xb6>
ffffffffc0201fe4:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201fe8:	6442                	ld	s0,16(sp)
ffffffffc0201fea:	60e2                	ld	ra,24(sp)
ffffffffc0201fec:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201fee:	4581                	li	a1,0
}
ffffffffc0201ff0:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ff2:	b9ad                	j	ffffffffc0201c6c <slob_free>
        intr_disable();
ffffffffc0201ff4:	9c1fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201ff8:	000a8797          	auipc	a5,0xa8
ffffffffc0201ffc:	6f87b783          	ld	a5,1784(a5) # ffffffffc02aa6f0 <bigblocks>
        return 1;
ffffffffc0202000:	4605                	li	a2,1
ffffffffc0202002:	fbad                	bnez	a5,ffffffffc0201f74 <kfree+0x26>
        intr_enable();
ffffffffc0202004:	9abfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202008:	bff1                	j	ffffffffc0201fe4 <kfree+0x96>
ffffffffc020200a:	9a5fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020200e:	b751                	j	ffffffffc0201f92 <kfree+0x44>
ffffffffc0202010:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0202012:	00004617          	auipc	a2,0x4
ffffffffc0202016:	2f660613          	addi	a2,a2,758 # ffffffffc0206308 <commands+0x7e8>
ffffffffc020201a:	06900593          	li	a1,105
ffffffffc020201e:	00004517          	auipc	a0,0x4
ffffffffc0202022:	2da50513          	addi	a0,a0,730 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc0202026:	c68fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc020202a:	86a2                	mv	a3,s0
ffffffffc020202c:	00005617          	auipc	a2,0x5
ffffffffc0202030:	83460613          	addi	a2,a2,-1996 # ffffffffc0206860 <default_pmm_manager+0xa8>
ffffffffc0202034:	07700593          	li	a1,119
ffffffffc0202038:	00004517          	auipc	a0,0x4
ffffffffc020203c:	2c050513          	addi	a0,a0,704 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc0202040:	c4efe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202044 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0202044:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0202046:	00004617          	auipc	a2,0x4
ffffffffc020204a:	2c260613          	addi	a2,a2,706 # ffffffffc0206308 <commands+0x7e8>
ffffffffc020204e:	06900593          	li	a1,105
ffffffffc0202052:	00004517          	auipc	a0,0x4
ffffffffc0202056:	2a650513          	addi	a0,a0,678 # ffffffffc02062f8 <commands+0x7d8>
pa2page(uintptr_t pa)
ffffffffc020205a:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc020205c:	c32fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202060 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0202060:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0202062:	00004617          	auipc	a2,0x4
ffffffffc0202066:	26e60613          	addi	a2,a2,622 # ffffffffc02062d0 <commands+0x7b0>
ffffffffc020206a:	07f00593          	li	a1,127
ffffffffc020206e:	00004517          	auipc	a0,0x4
ffffffffc0202072:	28a50513          	addi	a0,a0,650 # ffffffffc02062f8 <commands+0x7d8>
pte2page(pte_t pte)
ffffffffc0202076:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0202078:	c16fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020207c <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020207c:	100027f3          	csrr	a5,sstatus
ffffffffc0202080:	8b89                	andi	a5,a5,2
ffffffffc0202082:	e799                	bnez	a5,ffffffffc0202090 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0202084:	000a8797          	auipc	a5,0xa8
ffffffffc0202088:	6947b783          	ld	a5,1684(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc020208c:	6f9c                	ld	a5,24(a5)
ffffffffc020208e:	8782                	jr	a5
{
ffffffffc0202090:	1141                	addi	sp,sp,-16
ffffffffc0202092:	e406                	sd	ra,8(sp)
ffffffffc0202094:	e022                	sd	s0,0(sp)
ffffffffc0202096:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0202098:	91dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020209c:	000a8797          	auipc	a5,0xa8
ffffffffc02020a0:	67c7b783          	ld	a5,1660(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc02020a4:	6f9c                	ld	a5,24(a5)
ffffffffc02020a6:	8522                	mv	a0,s0
ffffffffc02020a8:	9782                	jalr	a5
ffffffffc02020aa:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02020ac:	903fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02020b0:	60a2                	ld	ra,8(sp)
ffffffffc02020b2:	8522                	mv	a0,s0
ffffffffc02020b4:	6402                	ld	s0,0(sp)
ffffffffc02020b6:	0141                	addi	sp,sp,16
ffffffffc02020b8:	8082                	ret

ffffffffc02020ba <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02020ba:	100027f3          	csrr	a5,sstatus
ffffffffc02020be:	8b89                	andi	a5,a5,2
ffffffffc02020c0:	e799                	bnez	a5,ffffffffc02020ce <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02020c2:	000a8797          	auipc	a5,0xa8
ffffffffc02020c6:	6567b783          	ld	a5,1622(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc02020ca:	739c                	ld	a5,32(a5)
ffffffffc02020cc:	8782                	jr	a5
{
ffffffffc02020ce:	1101                	addi	sp,sp,-32
ffffffffc02020d0:	ec06                	sd	ra,24(sp)
ffffffffc02020d2:	e822                	sd	s0,16(sp)
ffffffffc02020d4:	e426                	sd	s1,8(sp)
ffffffffc02020d6:	842a                	mv	s0,a0
ffffffffc02020d8:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02020da:	8dbfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02020de:	000a8797          	auipc	a5,0xa8
ffffffffc02020e2:	63a7b783          	ld	a5,1594(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc02020e6:	739c                	ld	a5,32(a5)
ffffffffc02020e8:	85a6                	mv	a1,s1
ffffffffc02020ea:	8522                	mv	a0,s0
ffffffffc02020ec:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02020ee:	6442                	ld	s0,16(sp)
ffffffffc02020f0:	60e2                	ld	ra,24(sp)
ffffffffc02020f2:	64a2                	ld	s1,8(sp)
ffffffffc02020f4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02020f6:	8b9fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc02020fa <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02020fa:	100027f3          	csrr	a5,sstatus
ffffffffc02020fe:	8b89                	andi	a5,a5,2
ffffffffc0202100:	e799                	bnez	a5,ffffffffc020210e <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0202102:	000a8797          	auipc	a5,0xa8
ffffffffc0202106:	6167b783          	ld	a5,1558(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc020210a:	779c                	ld	a5,40(a5)
ffffffffc020210c:	8782                	jr	a5
{
ffffffffc020210e:	1141                	addi	sp,sp,-16
ffffffffc0202110:	e406                	sd	ra,8(sp)
ffffffffc0202112:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0202114:	8a1fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202118:	000a8797          	auipc	a5,0xa8
ffffffffc020211c:	6007b783          	ld	a5,1536(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc0202120:	779c                	ld	a5,40(a5)
ffffffffc0202122:	9782                	jalr	a5
ffffffffc0202124:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202126:	889fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc020212a:	60a2                	ld	ra,8(sp)
ffffffffc020212c:	8522                	mv	a0,s0
ffffffffc020212e:	6402                	ld	s0,0(sp)
ffffffffc0202130:	0141                	addi	sp,sp,16
ffffffffc0202132:	8082                	ret

ffffffffc0202134 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202134:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0202138:	1ff7f793          	andi	a5,a5,511
{
ffffffffc020213c:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc020213e:	078e                	slli	a5,a5,0x3
{
ffffffffc0202140:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202142:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0202146:	6094                	ld	a3,0(s1)
{
ffffffffc0202148:	f04a                	sd	s2,32(sp)
ffffffffc020214a:	ec4e                	sd	s3,24(sp)
ffffffffc020214c:	e852                	sd	s4,16(sp)
ffffffffc020214e:	fc06                	sd	ra,56(sp)
ffffffffc0202150:	f822                	sd	s0,48(sp)
ffffffffc0202152:	e456                	sd	s5,8(sp)
ffffffffc0202154:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0202156:	0016f793          	andi	a5,a3,1
{
ffffffffc020215a:	892e                	mv	s2,a1
ffffffffc020215c:	8a32                	mv	s4,a2
ffffffffc020215e:	000a8997          	auipc	s3,0xa8
ffffffffc0202162:	5aa98993          	addi	s3,s3,1450 # ffffffffc02aa708 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0202166:	efbd                	bnez	a5,ffffffffc02021e4 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202168:	14060c63          	beqz	a2,ffffffffc02022c0 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020216c:	100027f3          	csrr	a5,sstatus
ffffffffc0202170:	8b89                	andi	a5,a5,2
ffffffffc0202172:	14079963          	bnez	a5,ffffffffc02022c4 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202176:	000a8797          	auipc	a5,0xa8
ffffffffc020217a:	5a27b783          	ld	a5,1442(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc020217e:	6f9c                	ld	a5,24(a5)
ffffffffc0202180:	4505                	li	a0,1
ffffffffc0202182:	9782                	jalr	a5
ffffffffc0202184:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202186:	12040d63          	beqz	s0,ffffffffc02022c0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc020218a:	000a8b17          	auipc	s6,0xa8
ffffffffc020218e:	586b0b13          	addi	s6,s6,1414 # ffffffffc02aa710 <pages>
ffffffffc0202192:	000b3503          	ld	a0,0(s6)
ffffffffc0202196:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020219a:	000a8997          	auipc	s3,0xa8
ffffffffc020219e:	56e98993          	addi	s3,s3,1390 # ffffffffc02aa708 <npage>
ffffffffc02021a2:	40a40533          	sub	a0,s0,a0
ffffffffc02021a6:	8519                	srai	a0,a0,0x6
ffffffffc02021a8:	9556                	add	a0,a0,s5
ffffffffc02021aa:	0009b703          	ld	a4,0(s3)
ffffffffc02021ae:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc02021b2:	4685                	li	a3,1
ffffffffc02021b4:	c014                	sw	a3,0(s0)
ffffffffc02021b6:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02021b8:	0532                	slli	a0,a0,0xc
ffffffffc02021ba:	16e7f763          	bgeu	a5,a4,ffffffffc0202328 <get_pte+0x1f4>
ffffffffc02021be:	000a8797          	auipc	a5,0xa8
ffffffffc02021c2:	5627b783          	ld	a5,1378(a5) # ffffffffc02aa720 <va_pa_offset>
ffffffffc02021c6:	6605                	lui	a2,0x1
ffffffffc02021c8:	4581                	li	a1,0
ffffffffc02021ca:	953e                	add	a0,a0,a5
ffffffffc02021cc:	6bc030ef          	jal	ra,ffffffffc0205888 <memset>
    return page - pages + nbase;
ffffffffc02021d0:	000b3683          	ld	a3,0(s6)
ffffffffc02021d4:	40d406b3          	sub	a3,s0,a3
ffffffffc02021d8:	8699                	srai	a3,a3,0x6
ffffffffc02021da:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02021dc:	06aa                	slli	a3,a3,0xa
ffffffffc02021de:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02021e2:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02021e4:	77fd                	lui	a5,0xfffff
ffffffffc02021e6:	068a                	slli	a3,a3,0x2
ffffffffc02021e8:	0009b703          	ld	a4,0(s3)
ffffffffc02021ec:	8efd                	and	a3,a3,a5
ffffffffc02021ee:	00c6d793          	srli	a5,a3,0xc
ffffffffc02021f2:	10e7ff63          	bgeu	a5,a4,ffffffffc0202310 <get_pte+0x1dc>
ffffffffc02021f6:	000a8a97          	auipc	s5,0xa8
ffffffffc02021fa:	52aa8a93          	addi	s5,s5,1322 # ffffffffc02aa720 <va_pa_offset>
ffffffffc02021fe:	000ab403          	ld	s0,0(s5)
ffffffffc0202202:	01595793          	srli	a5,s2,0x15
ffffffffc0202206:	1ff7f793          	andi	a5,a5,511
ffffffffc020220a:	96a2                	add	a3,a3,s0
ffffffffc020220c:	00379413          	slli	s0,a5,0x3
ffffffffc0202210:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0202212:	6014                	ld	a3,0(s0)
ffffffffc0202214:	0016f793          	andi	a5,a3,1
ffffffffc0202218:	ebad                	bnez	a5,ffffffffc020228a <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020221a:	0a0a0363          	beqz	s4,ffffffffc02022c0 <get_pte+0x18c>
ffffffffc020221e:	100027f3          	csrr	a5,sstatus
ffffffffc0202222:	8b89                	andi	a5,a5,2
ffffffffc0202224:	efcd                	bnez	a5,ffffffffc02022de <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202226:	000a8797          	auipc	a5,0xa8
ffffffffc020222a:	4f27b783          	ld	a5,1266(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc020222e:	6f9c                	ld	a5,24(a5)
ffffffffc0202230:	4505                	li	a0,1
ffffffffc0202232:	9782                	jalr	a5
ffffffffc0202234:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202236:	c4c9                	beqz	s1,ffffffffc02022c0 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0202238:	000a8b17          	auipc	s6,0xa8
ffffffffc020223c:	4d8b0b13          	addi	s6,s6,1240 # ffffffffc02aa710 <pages>
ffffffffc0202240:	000b3503          	ld	a0,0(s6)
ffffffffc0202244:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202248:	0009b703          	ld	a4,0(s3)
ffffffffc020224c:	40a48533          	sub	a0,s1,a0
ffffffffc0202250:	8519                	srai	a0,a0,0x6
ffffffffc0202252:	9552                	add	a0,a0,s4
ffffffffc0202254:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202258:	4685                	li	a3,1
ffffffffc020225a:	c094                	sw	a3,0(s1)
ffffffffc020225c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020225e:	0532                	slli	a0,a0,0xc
ffffffffc0202260:	0ee7f163          	bgeu	a5,a4,ffffffffc0202342 <get_pte+0x20e>
ffffffffc0202264:	000ab783          	ld	a5,0(s5)
ffffffffc0202268:	6605                	lui	a2,0x1
ffffffffc020226a:	4581                	li	a1,0
ffffffffc020226c:	953e                	add	a0,a0,a5
ffffffffc020226e:	61a030ef          	jal	ra,ffffffffc0205888 <memset>
    return page - pages + nbase;
ffffffffc0202272:	000b3683          	ld	a3,0(s6)
ffffffffc0202276:	40d486b3          	sub	a3,s1,a3
ffffffffc020227a:	8699                	srai	a3,a3,0x6
ffffffffc020227c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020227e:	06aa                	slli	a3,a3,0xa
ffffffffc0202280:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202284:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202286:	0009b703          	ld	a4,0(s3)
ffffffffc020228a:	068a                	slli	a3,a3,0x2
ffffffffc020228c:	757d                	lui	a0,0xfffff
ffffffffc020228e:	8ee9                	and	a3,a3,a0
ffffffffc0202290:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202294:	06e7f263          	bgeu	a5,a4,ffffffffc02022f8 <get_pte+0x1c4>
ffffffffc0202298:	000ab503          	ld	a0,0(s5)
ffffffffc020229c:	00c95913          	srli	s2,s2,0xc
ffffffffc02022a0:	1ff97913          	andi	s2,s2,511
ffffffffc02022a4:	96aa                	add	a3,a3,a0
ffffffffc02022a6:	00391513          	slli	a0,s2,0x3
ffffffffc02022aa:	9536                	add	a0,a0,a3
}
ffffffffc02022ac:	70e2                	ld	ra,56(sp)
ffffffffc02022ae:	7442                	ld	s0,48(sp)
ffffffffc02022b0:	74a2                	ld	s1,40(sp)
ffffffffc02022b2:	7902                	ld	s2,32(sp)
ffffffffc02022b4:	69e2                	ld	s3,24(sp)
ffffffffc02022b6:	6a42                	ld	s4,16(sp)
ffffffffc02022b8:	6aa2                	ld	s5,8(sp)
ffffffffc02022ba:	6b02                	ld	s6,0(sp)
ffffffffc02022bc:	6121                	addi	sp,sp,64
ffffffffc02022be:	8082                	ret
            return NULL;
ffffffffc02022c0:	4501                	li	a0,0
ffffffffc02022c2:	b7ed                	j	ffffffffc02022ac <get_pte+0x178>
        intr_disable();
ffffffffc02022c4:	ef0fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02022c8:	000a8797          	auipc	a5,0xa8
ffffffffc02022cc:	4507b783          	ld	a5,1104(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc02022d0:	6f9c                	ld	a5,24(a5)
ffffffffc02022d2:	4505                	li	a0,1
ffffffffc02022d4:	9782                	jalr	a5
ffffffffc02022d6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02022d8:	ed6fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02022dc:	b56d                	j	ffffffffc0202186 <get_pte+0x52>
        intr_disable();
ffffffffc02022de:	ed6fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02022e2:	000a8797          	auipc	a5,0xa8
ffffffffc02022e6:	4367b783          	ld	a5,1078(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc02022ea:	6f9c                	ld	a5,24(a5)
ffffffffc02022ec:	4505                	li	a0,1
ffffffffc02022ee:	9782                	jalr	a5
ffffffffc02022f0:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc02022f2:	ebcfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02022f6:	b781                	j	ffffffffc0202236 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02022f8:	00004617          	auipc	a2,0x4
ffffffffc02022fc:	04860613          	addi	a2,a2,72 # ffffffffc0206340 <commands+0x820>
ffffffffc0202300:	0fa00593          	li	a1,250
ffffffffc0202304:	00004517          	auipc	a0,0x4
ffffffffc0202308:	58450513          	addi	a0,a0,1412 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020230c:	982fe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202310:	00004617          	auipc	a2,0x4
ffffffffc0202314:	03060613          	addi	a2,a2,48 # ffffffffc0206340 <commands+0x820>
ffffffffc0202318:	0ed00593          	li	a1,237
ffffffffc020231c:	00004517          	auipc	a0,0x4
ffffffffc0202320:	56c50513          	addi	a0,a0,1388 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc0202324:	96afe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202328:	86aa                	mv	a3,a0
ffffffffc020232a:	00004617          	auipc	a2,0x4
ffffffffc020232e:	01660613          	addi	a2,a2,22 # ffffffffc0206340 <commands+0x820>
ffffffffc0202332:	0e900593          	li	a1,233
ffffffffc0202336:	00004517          	auipc	a0,0x4
ffffffffc020233a:	55250513          	addi	a0,a0,1362 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020233e:	950fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202342:	86aa                	mv	a3,a0
ffffffffc0202344:	00004617          	auipc	a2,0x4
ffffffffc0202348:	ffc60613          	addi	a2,a2,-4 # ffffffffc0206340 <commands+0x820>
ffffffffc020234c:	0f700593          	li	a1,247
ffffffffc0202350:	00004517          	auipc	a0,0x4
ffffffffc0202354:	53850513          	addi	a0,a0,1336 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc0202358:	936fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020235c <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc020235c:	1141                	addi	sp,sp,-16
ffffffffc020235e:	e022                	sd	s0,0(sp)
ffffffffc0202360:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202362:	4601                	li	a2,0
{
ffffffffc0202364:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202366:	dcfff0ef          	jal	ra,ffffffffc0202134 <get_pte>
    if (ptep_store != NULL)
ffffffffc020236a:	c011                	beqz	s0,ffffffffc020236e <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc020236c:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020236e:	c511                	beqz	a0,ffffffffc020237a <get_page+0x1e>
ffffffffc0202370:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202372:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202374:	0017f713          	andi	a4,a5,1
ffffffffc0202378:	e709                	bnez	a4,ffffffffc0202382 <get_page+0x26>
}
ffffffffc020237a:	60a2                	ld	ra,8(sp)
ffffffffc020237c:	6402                	ld	s0,0(sp)
ffffffffc020237e:	0141                	addi	sp,sp,16
ffffffffc0202380:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202382:	078a                	slli	a5,a5,0x2
ffffffffc0202384:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202386:	000a8717          	auipc	a4,0xa8
ffffffffc020238a:	38273703          	ld	a4,898(a4) # ffffffffc02aa708 <npage>
ffffffffc020238e:	00e7ff63          	bgeu	a5,a4,ffffffffc02023ac <get_page+0x50>
ffffffffc0202392:	60a2                	ld	ra,8(sp)
ffffffffc0202394:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0202396:	fff80537          	lui	a0,0xfff80
ffffffffc020239a:	97aa                	add	a5,a5,a0
ffffffffc020239c:	079a                	slli	a5,a5,0x6
ffffffffc020239e:	000a8517          	auipc	a0,0xa8
ffffffffc02023a2:	37253503          	ld	a0,882(a0) # ffffffffc02aa710 <pages>
ffffffffc02023a6:	953e                	add	a0,a0,a5
ffffffffc02023a8:	0141                	addi	sp,sp,16
ffffffffc02023aa:	8082                	ret
ffffffffc02023ac:	c99ff0ef          	jal	ra,ffffffffc0202044 <pa2page.part.0>

ffffffffc02023b0 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02023b0:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023b2:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02023b6:	f486                	sd	ra,104(sp)
ffffffffc02023b8:	f0a2                	sd	s0,96(sp)
ffffffffc02023ba:	eca6                	sd	s1,88(sp)
ffffffffc02023bc:	e8ca                	sd	s2,80(sp)
ffffffffc02023be:	e4ce                	sd	s3,72(sp)
ffffffffc02023c0:	e0d2                	sd	s4,64(sp)
ffffffffc02023c2:	fc56                	sd	s5,56(sp)
ffffffffc02023c4:	f85a                	sd	s6,48(sp)
ffffffffc02023c6:	f45e                	sd	s7,40(sp)
ffffffffc02023c8:	f062                	sd	s8,32(sp)
ffffffffc02023ca:	ec66                	sd	s9,24(sp)
ffffffffc02023cc:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023ce:	17d2                	slli	a5,a5,0x34
ffffffffc02023d0:	e3ed                	bnez	a5,ffffffffc02024b2 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc02023d2:	002007b7          	lui	a5,0x200
ffffffffc02023d6:	842e                	mv	s0,a1
ffffffffc02023d8:	0ef5ed63          	bltu	a1,a5,ffffffffc02024d2 <unmap_range+0x122>
ffffffffc02023dc:	8932                	mv	s2,a2
ffffffffc02023de:	0ec5fa63          	bgeu	a1,a2,ffffffffc02024d2 <unmap_range+0x122>
ffffffffc02023e2:	4785                	li	a5,1
ffffffffc02023e4:	07fe                	slli	a5,a5,0x1f
ffffffffc02023e6:	0ec7e663          	bltu	a5,a2,ffffffffc02024d2 <unmap_range+0x122>
ffffffffc02023ea:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02023ec:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02023ee:	000a8c97          	auipc	s9,0xa8
ffffffffc02023f2:	31ac8c93          	addi	s9,s9,794 # ffffffffc02aa708 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02023f6:	000a8c17          	auipc	s8,0xa8
ffffffffc02023fa:	31ac0c13          	addi	s8,s8,794 # ffffffffc02aa710 <pages>
ffffffffc02023fe:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc0202402:	000a8d17          	auipc	s10,0xa8
ffffffffc0202406:	316d0d13          	addi	s10,s10,790 # ffffffffc02aa718 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020240a:	00200b37          	lui	s6,0x200
ffffffffc020240e:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202412:	4601                	li	a2,0
ffffffffc0202414:	85a2                	mv	a1,s0
ffffffffc0202416:	854e                	mv	a0,s3
ffffffffc0202418:	d1dff0ef          	jal	ra,ffffffffc0202134 <get_pte>
ffffffffc020241c:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc020241e:	cd29                	beqz	a0,ffffffffc0202478 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc0202420:	611c                	ld	a5,0(a0)
ffffffffc0202422:	e395                	bnez	a5,ffffffffc0202446 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202424:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202426:	ff2466e3          	bltu	s0,s2,ffffffffc0202412 <unmap_range+0x62>
}
ffffffffc020242a:	70a6                	ld	ra,104(sp)
ffffffffc020242c:	7406                	ld	s0,96(sp)
ffffffffc020242e:	64e6                	ld	s1,88(sp)
ffffffffc0202430:	6946                	ld	s2,80(sp)
ffffffffc0202432:	69a6                	ld	s3,72(sp)
ffffffffc0202434:	6a06                	ld	s4,64(sp)
ffffffffc0202436:	7ae2                	ld	s5,56(sp)
ffffffffc0202438:	7b42                	ld	s6,48(sp)
ffffffffc020243a:	7ba2                	ld	s7,40(sp)
ffffffffc020243c:	7c02                	ld	s8,32(sp)
ffffffffc020243e:	6ce2                	ld	s9,24(sp)
ffffffffc0202440:	6d42                	ld	s10,16(sp)
ffffffffc0202442:	6165                	addi	sp,sp,112
ffffffffc0202444:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202446:	0017f713          	andi	a4,a5,1
ffffffffc020244a:	df69                	beqz	a4,ffffffffc0202424 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc020244c:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202450:	078a                	slli	a5,a5,0x2
ffffffffc0202452:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202454:	08e7ff63          	bgeu	a5,a4,ffffffffc02024f2 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202458:	000c3503          	ld	a0,0(s8)
ffffffffc020245c:	97de                	add	a5,a5,s7
ffffffffc020245e:	079a                	slli	a5,a5,0x6
ffffffffc0202460:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202462:	411c                	lw	a5,0(a0)
ffffffffc0202464:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202468:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020246a:	cf11                	beqz	a4,ffffffffc0202486 <unmap_range+0xd6>
        *ptep = 0;
ffffffffc020246c:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202470:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202474:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202476:	bf45                	j	ffffffffc0202426 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202478:	945a                	add	s0,s0,s6
ffffffffc020247a:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020247e:	d455                	beqz	s0,ffffffffc020242a <unmap_range+0x7a>
ffffffffc0202480:	f92469e3          	bltu	s0,s2,ffffffffc0202412 <unmap_range+0x62>
ffffffffc0202484:	b75d                	j	ffffffffc020242a <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202486:	100027f3          	csrr	a5,sstatus
ffffffffc020248a:	8b89                	andi	a5,a5,2
ffffffffc020248c:	e799                	bnez	a5,ffffffffc020249a <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020248e:	000d3783          	ld	a5,0(s10)
ffffffffc0202492:	4585                	li	a1,1
ffffffffc0202494:	739c                	ld	a5,32(a5)
ffffffffc0202496:	9782                	jalr	a5
    if (flag)
ffffffffc0202498:	bfd1                	j	ffffffffc020246c <unmap_range+0xbc>
ffffffffc020249a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020249c:	d18fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02024a0:	000d3783          	ld	a5,0(s10)
ffffffffc02024a4:	6522                	ld	a0,8(sp)
ffffffffc02024a6:	4585                	li	a1,1
ffffffffc02024a8:	739c                	ld	a5,32(a5)
ffffffffc02024aa:	9782                	jalr	a5
        intr_enable();
ffffffffc02024ac:	d02fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02024b0:	bf75                	j	ffffffffc020246c <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02024b2:	00004697          	auipc	a3,0x4
ffffffffc02024b6:	3e668693          	addi	a3,a3,998 # ffffffffc0206898 <default_pmm_manager+0xe0>
ffffffffc02024ba:	00004617          	auipc	a2,0x4
ffffffffc02024be:	f4e60613          	addi	a2,a2,-178 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02024c2:	12000593          	li	a1,288
ffffffffc02024c6:	00004517          	auipc	a0,0x4
ffffffffc02024ca:	3c250513          	addi	a0,a0,962 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02024ce:	fc1fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02024d2:	00004697          	auipc	a3,0x4
ffffffffc02024d6:	3f668693          	addi	a3,a3,1014 # ffffffffc02068c8 <default_pmm_manager+0x110>
ffffffffc02024da:	00004617          	auipc	a2,0x4
ffffffffc02024de:	f2e60613          	addi	a2,a2,-210 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02024e2:	12100593          	li	a1,289
ffffffffc02024e6:	00004517          	auipc	a0,0x4
ffffffffc02024ea:	3a250513          	addi	a0,a0,930 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02024ee:	fa1fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02024f2:	b53ff0ef          	jal	ra,ffffffffc0202044 <pa2page.part.0>

ffffffffc02024f6 <exit_range>:
{
ffffffffc02024f6:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02024f8:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02024fc:	fc86                	sd	ra,120(sp)
ffffffffc02024fe:	f8a2                	sd	s0,112(sp)
ffffffffc0202500:	f4a6                	sd	s1,104(sp)
ffffffffc0202502:	f0ca                	sd	s2,96(sp)
ffffffffc0202504:	ecce                	sd	s3,88(sp)
ffffffffc0202506:	e8d2                	sd	s4,80(sp)
ffffffffc0202508:	e4d6                	sd	s5,72(sp)
ffffffffc020250a:	e0da                	sd	s6,64(sp)
ffffffffc020250c:	fc5e                	sd	s7,56(sp)
ffffffffc020250e:	f862                	sd	s8,48(sp)
ffffffffc0202510:	f466                	sd	s9,40(sp)
ffffffffc0202512:	f06a                	sd	s10,32(sp)
ffffffffc0202514:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202516:	17d2                	slli	a5,a5,0x34
ffffffffc0202518:	20079a63          	bnez	a5,ffffffffc020272c <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc020251c:	002007b7          	lui	a5,0x200
ffffffffc0202520:	24f5e463          	bltu	a1,a5,ffffffffc0202768 <exit_range+0x272>
ffffffffc0202524:	8ab2                	mv	s5,a2
ffffffffc0202526:	24c5f163          	bgeu	a1,a2,ffffffffc0202768 <exit_range+0x272>
ffffffffc020252a:	4785                	li	a5,1
ffffffffc020252c:	07fe                	slli	a5,a5,0x1f
ffffffffc020252e:	22c7ed63          	bltu	a5,a2,ffffffffc0202768 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202532:	c00009b7          	lui	s3,0xc0000
ffffffffc0202536:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020253a:	ffe00937          	lui	s2,0xffe00
ffffffffc020253e:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc0202542:	5cfd                	li	s9,-1
ffffffffc0202544:	8c2a                	mv	s8,a0
ffffffffc0202546:	0125f933          	and	s2,a1,s2
ffffffffc020254a:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc020254c:	000a8d17          	auipc	s10,0xa8
ffffffffc0202550:	1bcd0d13          	addi	s10,s10,444 # ffffffffc02aa708 <npage>
    return KADDR(page2pa(page));
ffffffffc0202554:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202558:	000a8717          	auipc	a4,0xa8
ffffffffc020255c:	1b870713          	addi	a4,a4,440 # ffffffffc02aa710 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc0202560:	000a8d97          	auipc	s11,0xa8
ffffffffc0202564:	1b8d8d93          	addi	s11,s11,440 # ffffffffc02aa718 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202568:	c0000437          	lui	s0,0xc0000
ffffffffc020256c:	944e                	add	s0,s0,s3
ffffffffc020256e:	8079                	srli	s0,s0,0x1e
ffffffffc0202570:	1ff47413          	andi	s0,s0,511
ffffffffc0202574:	040e                	slli	s0,s0,0x3
ffffffffc0202576:	9462                	add	s0,s0,s8
ffffffffc0202578:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ee0>
        if (pde1 & PTE_V)
ffffffffc020257c:	001a7793          	andi	a5,s4,1
ffffffffc0202580:	eb99                	bnez	a5,ffffffffc0202596 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc0202582:	12098463          	beqz	s3,ffffffffc02026aa <exit_range+0x1b4>
ffffffffc0202586:	400007b7          	lui	a5,0x40000
ffffffffc020258a:	97ce                	add	a5,a5,s3
ffffffffc020258c:	894e                	mv	s2,s3
ffffffffc020258e:	1159fe63          	bgeu	s3,s5,ffffffffc02026aa <exit_range+0x1b4>
ffffffffc0202592:	89be                	mv	s3,a5
ffffffffc0202594:	bfd1                	j	ffffffffc0202568 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc0202596:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020259a:	0a0a                	slli	s4,s4,0x2
ffffffffc020259c:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc02025a0:	1cfa7263          	bgeu	s4,a5,ffffffffc0202764 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02025a4:	fff80637          	lui	a2,0xfff80
ffffffffc02025a8:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc02025aa:	000806b7          	lui	a3,0x80
ffffffffc02025ae:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02025b0:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02025b4:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02025b6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02025b8:	18f5fa63          	bgeu	a1,a5,ffffffffc020274c <exit_range+0x256>
ffffffffc02025bc:	000a8817          	auipc	a6,0xa8
ffffffffc02025c0:	16480813          	addi	a6,a6,356 # ffffffffc02aa720 <va_pa_offset>
ffffffffc02025c4:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc02025c8:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02025ca:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02025ce:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02025d0:	00080337          	lui	t1,0x80
ffffffffc02025d4:	6885                	lui	a7,0x1
ffffffffc02025d6:	a819                	j	ffffffffc02025ec <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02025d8:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02025da:	002007b7          	lui	a5,0x200
ffffffffc02025de:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02025e0:	08090c63          	beqz	s2,ffffffffc0202678 <exit_range+0x182>
ffffffffc02025e4:	09397a63          	bgeu	s2,s3,ffffffffc0202678 <exit_range+0x182>
ffffffffc02025e8:	0f597063          	bgeu	s2,s5,ffffffffc02026c8 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02025ec:	01595493          	srli	s1,s2,0x15
ffffffffc02025f0:	1ff4f493          	andi	s1,s1,511
ffffffffc02025f4:	048e                	slli	s1,s1,0x3
ffffffffc02025f6:	94da                	add	s1,s1,s6
ffffffffc02025f8:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc02025fa:	0017f693          	andi	a3,a5,1
ffffffffc02025fe:	dee9                	beqz	a3,ffffffffc02025d8 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc0202600:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202604:	078a                	slli	a5,a5,0x2
ffffffffc0202606:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202608:	14b7fe63          	bgeu	a5,a1,ffffffffc0202764 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020260c:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc020260e:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc0202612:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202616:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020261a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020261c:	12bef863          	bgeu	t4,a1,ffffffffc020274c <exit_range+0x256>
ffffffffc0202620:	00083783          	ld	a5,0(a6)
ffffffffc0202624:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202626:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc020262a:	629c                	ld	a5,0(a3)
ffffffffc020262c:	8b85                	andi	a5,a5,1
ffffffffc020262e:	f7d5                	bnez	a5,ffffffffc02025da <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202630:	06a1                	addi	a3,a3,8
ffffffffc0202632:	fed59ce3          	bne	a1,a3,ffffffffc020262a <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202636:	631c                	ld	a5,0(a4)
ffffffffc0202638:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020263a:	100027f3          	csrr	a5,sstatus
ffffffffc020263e:	8b89                	andi	a5,a5,2
ffffffffc0202640:	e7d9                	bnez	a5,ffffffffc02026ce <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc0202642:	000db783          	ld	a5,0(s11)
ffffffffc0202646:	4585                	li	a1,1
ffffffffc0202648:	e032                	sd	a2,0(sp)
ffffffffc020264a:	739c                	ld	a5,32(a5)
ffffffffc020264c:	9782                	jalr	a5
    if (flag)
ffffffffc020264e:	6602                	ld	a2,0(sp)
ffffffffc0202650:	000a8817          	auipc	a6,0xa8
ffffffffc0202654:	0d080813          	addi	a6,a6,208 # ffffffffc02aa720 <va_pa_offset>
ffffffffc0202658:	fff80e37          	lui	t3,0xfff80
ffffffffc020265c:	00080337          	lui	t1,0x80
ffffffffc0202660:	6885                	lui	a7,0x1
ffffffffc0202662:	000a8717          	auipc	a4,0xa8
ffffffffc0202666:	0ae70713          	addi	a4,a4,174 # ffffffffc02aa710 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020266a:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020266e:	002007b7          	lui	a5,0x200
ffffffffc0202672:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202674:	f60918e3          	bnez	s2,ffffffffc02025e4 <exit_range+0xee>
            if (free_pd0)
ffffffffc0202678:	f00b85e3          	beqz	s7,ffffffffc0202582 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc020267c:	000d3783          	ld	a5,0(s10)
ffffffffc0202680:	0efa7263          	bgeu	s4,a5,ffffffffc0202764 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202684:	6308                	ld	a0,0(a4)
ffffffffc0202686:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202688:	100027f3          	csrr	a5,sstatus
ffffffffc020268c:	8b89                	andi	a5,a5,2
ffffffffc020268e:	efad                	bnez	a5,ffffffffc0202708 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0202690:	000db783          	ld	a5,0(s11)
ffffffffc0202694:	4585                	li	a1,1
ffffffffc0202696:	739c                	ld	a5,32(a5)
ffffffffc0202698:	9782                	jalr	a5
ffffffffc020269a:	000a8717          	auipc	a4,0xa8
ffffffffc020269e:	07670713          	addi	a4,a4,118 # ffffffffc02aa710 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02026a2:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc02026a6:	ee0990e3          	bnez	s3,ffffffffc0202586 <exit_range+0x90>
}
ffffffffc02026aa:	70e6                	ld	ra,120(sp)
ffffffffc02026ac:	7446                	ld	s0,112(sp)
ffffffffc02026ae:	74a6                	ld	s1,104(sp)
ffffffffc02026b0:	7906                	ld	s2,96(sp)
ffffffffc02026b2:	69e6                	ld	s3,88(sp)
ffffffffc02026b4:	6a46                	ld	s4,80(sp)
ffffffffc02026b6:	6aa6                	ld	s5,72(sp)
ffffffffc02026b8:	6b06                	ld	s6,64(sp)
ffffffffc02026ba:	7be2                	ld	s7,56(sp)
ffffffffc02026bc:	7c42                	ld	s8,48(sp)
ffffffffc02026be:	7ca2                	ld	s9,40(sp)
ffffffffc02026c0:	7d02                	ld	s10,32(sp)
ffffffffc02026c2:	6de2                	ld	s11,24(sp)
ffffffffc02026c4:	6109                	addi	sp,sp,128
ffffffffc02026c6:	8082                	ret
            if (free_pd0)
ffffffffc02026c8:	ea0b8fe3          	beqz	s7,ffffffffc0202586 <exit_range+0x90>
ffffffffc02026cc:	bf45                	j	ffffffffc020267c <exit_range+0x186>
ffffffffc02026ce:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc02026d0:	e42a                	sd	a0,8(sp)
ffffffffc02026d2:	ae2fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02026d6:	000db783          	ld	a5,0(s11)
ffffffffc02026da:	6522                	ld	a0,8(sp)
ffffffffc02026dc:	4585                	li	a1,1
ffffffffc02026de:	739c                	ld	a5,32(a5)
ffffffffc02026e0:	9782                	jalr	a5
        intr_enable();
ffffffffc02026e2:	accfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02026e6:	6602                	ld	a2,0(sp)
ffffffffc02026e8:	000a8717          	auipc	a4,0xa8
ffffffffc02026ec:	02870713          	addi	a4,a4,40 # ffffffffc02aa710 <pages>
ffffffffc02026f0:	6885                	lui	a7,0x1
ffffffffc02026f2:	00080337          	lui	t1,0x80
ffffffffc02026f6:	fff80e37          	lui	t3,0xfff80
ffffffffc02026fa:	000a8817          	auipc	a6,0xa8
ffffffffc02026fe:	02680813          	addi	a6,a6,38 # ffffffffc02aa720 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202702:	0004b023          	sd	zero,0(s1)
ffffffffc0202706:	b7a5                	j	ffffffffc020266e <exit_range+0x178>
ffffffffc0202708:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc020270a:	aaafe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020270e:	000db783          	ld	a5,0(s11)
ffffffffc0202712:	6502                	ld	a0,0(sp)
ffffffffc0202714:	4585                	li	a1,1
ffffffffc0202716:	739c                	ld	a5,32(a5)
ffffffffc0202718:	9782                	jalr	a5
        intr_enable();
ffffffffc020271a:	a94fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020271e:	000a8717          	auipc	a4,0xa8
ffffffffc0202722:	ff270713          	addi	a4,a4,-14 # ffffffffc02aa710 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202726:	00043023          	sd	zero,0(s0)
ffffffffc020272a:	bfb5                	j	ffffffffc02026a6 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020272c:	00004697          	auipc	a3,0x4
ffffffffc0202730:	16c68693          	addi	a3,a3,364 # ffffffffc0206898 <default_pmm_manager+0xe0>
ffffffffc0202734:	00004617          	auipc	a2,0x4
ffffffffc0202738:	cd460613          	addi	a2,a2,-812 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020273c:	13500593          	li	a1,309
ffffffffc0202740:	00004517          	auipc	a0,0x4
ffffffffc0202744:	14850513          	addi	a0,a0,328 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc0202748:	d47fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc020274c:	00004617          	auipc	a2,0x4
ffffffffc0202750:	bf460613          	addi	a2,a2,-1036 # ffffffffc0206340 <commands+0x820>
ffffffffc0202754:	07100593          	li	a1,113
ffffffffc0202758:	00004517          	auipc	a0,0x4
ffffffffc020275c:	ba050513          	addi	a0,a0,-1120 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc0202760:	d2ffd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202764:	8e1ff0ef          	jal	ra,ffffffffc0202044 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202768:	00004697          	auipc	a3,0x4
ffffffffc020276c:	16068693          	addi	a3,a3,352 # ffffffffc02068c8 <default_pmm_manager+0x110>
ffffffffc0202770:	00004617          	auipc	a2,0x4
ffffffffc0202774:	c9860613          	addi	a2,a2,-872 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0202778:	13600593          	li	a1,310
ffffffffc020277c:	00004517          	auipc	a0,0x4
ffffffffc0202780:	10c50513          	addi	a0,a0,268 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc0202784:	d0bfd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202788 <page_remove>:
{
ffffffffc0202788:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020278a:	4601                	li	a2,0
{
ffffffffc020278c:	ec26                	sd	s1,24(sp)
ffffffffc020278e:	f406                	sd	ra,40(sp)
ffffffffc0202790:	f022                	sd	s0,32(sp)
ffffffffc0202792:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202794:	9a1ff0ef          	jal	ra,ffffffffc0202134 <get_pte>
    if (ptep != NULL)
ffffffffc0202798:	c511                	beqz	a0,ffffffffc02027a4 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc020279a:	611c                	ld	a5,0(a0)
ffffffffc020279c:	842a                	mv	s0,a0
ffffffffc020279e:	0017f713          	andi	a4,a5,1
ffffffffc02027a2:	e711                	bnez	a4,ffffffffc02027ae <page_remove+0x26>
}
ffffffffc02027a4:	70a2                	ld	ra,40(sp)
ffffffffc02027a6:	7402                	ld	s0,32(sp)
ffffffffc02027a8:	64e2                	ld	s1,24(sp)
ffffffffc02027aa:	6145                	addi	sp,sp,48
ffffffffc02027ac:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02027ae:	078a                	slli	a5,a5,0x2
ffffffffc02027b0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02027b2:	000a8717          	auipc	a4,0xa8
ffffffffc02027b6:	f5673703          	ld	a4,-170(a4) # ffffffffc02aa708 <npage>
ffffffffc02027ba:	06e7f363          	bgeu	a5,a4,ffffffffc0202820 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02027be:	fff80537          	lui	a0,0xfff80
ffffffffc02027c2:	97aa                	add	a5,a5,a0
ffffffffc02027c4:	079a                	slli	a5,a5,0x6
ffffffffc02027c6:	000a8517          	auipc	a0,0xa8
ffffffffc02027ca:	f4a53503          	ld	a0,-182(a0) # ffffffffc02aa710 <pages>
ffffffffc02027ce:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02027d0:	411c                	lw	a5,0(a0)
ffffffffc02027d2:	fff7871b          	addiw	a4,a5,-1
ffffffffc02027d6:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02027d8:	cb11                	beqz	a4,ffffffffc02027ec <page_remove+0x64>
        *ptep = 0;
ffffffffc02027da:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027de:	12048073          	sfence.vma	s1
}
ffffffffc02027e2:	70a2                	ld	ra,40(sp)
ffffffffc02027e4:	7402                	ld	s0,32(sp)
ffffffffc02027e6:	64e2                	ld	s1,24(sp)
ffffffffc02027e8:	6145                	addi	sp,sp,48
ffffffffc02027ea:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02027ec:	100027f3          	csrr	a5,sstatus
ffffffffc02027f0:	8b89                	andi	a5,a5,2
ffffffffc02027f2:	eb89                	bnez	a5,ffffffffc0202804 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc02027f4:	000a8797          	auipc	a5,0xa8
ffffffffc02027f8:	f247b783          	ld	a5,-220(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc02027fc:	739c                	ld	a5,32(a5)
ffffffffc02027fe:	4585                	li	a1,1
ffffffffc0202800:	9782                	jalr	a5
    if (flag)
ffffffffc0202802:	bfe1                	j	ffffffffc02027da <page_remove+0x52>
        intr_disable();
ffffffffc0202804:	e42a                	sd	a0,8(sp)
ffffffffc0202806:	9aefe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020280a:	000a8797          	auipc	a5,0xa8
ffffffffc020280e:	f0e7b783          	ld	a5,-242(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc0202812:	739c                	ld	a5,32(a5)
ffffffffc0202814:	6522                	ld	a0,8(sp)
ffffffffc0202816:	4585                	li	a1,1
ffffffffc0202818:	9782                	jalr	a5
        intr_enable();
ffffffffc020281a:	994fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020281e:	bf75                	j	ffffffffc02027da <page_remove+0x52>
ffffffffc0202820:	825ff0ef          	jal	ra,ffffffffc0202044 <pa2page.part.0>

ffffffffc0202824 <page_insert>:
{
ffffffffc0202824:	7139                	addi	sp,sp,-64
ffffffffc0202826:	e852                	sd	s4,16(sp)
ffffffffc0202828:	8a32                	mv	s4,a2
ffffffffc020282a:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020282c:	4605                	li	a2,1
{
ffffffffc020282e:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202830:	85d2                	mv	a1,s4
{
ffffffffc0202832:	f426                	sd	s1,40(sp)
ffffffffc0202834:	fc06                	sd	ra,56(sp)
ffffffffc0202836:	f04a                	sd	s2,32(sp)
ffffffffc0202838:	ec4e                	sd	s3,24(sp)
ffffffffc020283a:	e456                	sd	s5,8(sp)
ffffffffc020283c:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020283e:	8f7ff0ef          	jal	ra,ffffffffc0202134 <get_pte>
    if (ptep == NULL)
ffffffffc0202842:	c961                	beqz	a0,ffffffffc0202912 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202844:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202846:	611c                	ld	a5,0(a0)
ffffffffc0202848:	89aa                	mv	s3,a0
ffffffffc020284a:	0016871b          	addiw	a4,a3,1
ffffffffc020284e:	c018                	sw	a4,0(s0)
ffffffffc0202850:	0017f713          	andi	a4,a5,1
ffffffffc0202854:	ef05                	bnez	a4,ffffffffc020288c <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202856:	000a8717          	auipc	a4,0xa8
ffffffffc020285a:	eba73703          	ld	a4,-326(a4) # ffffffffc02aa710 <pages>
ffffffffc020285e:	8c19                	sub	s0,s0,a4
ffffffffc0202860:	000807b7          	lui	a5,0x80
ffffffffc0202864:	8419                	srai	s0,s0,0x6
ffffffffc0202866:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202868:	042a                	slli	s0,s0,0xa
ffffffffc020286a:	8cc1                	or	s1,s1,s0
ffffffffc020286c:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202870:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ee0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202874:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202878:	4501                	li	a0,0
}
ffffffffc020287a:	70e2                	ld	ra,56(sp)
ffffffffc020287c:	7442                	ld	s0,48(sp)
ffffffffc020287e:	74a2                	ld	s1,40(sp)
ffffffffc0202880:	7902                	ld	s2,32(sp)
ffffffffc0202882:	69e2                	ld	s3,24(sp)
ffffffffc0202884:	6a42                	ld	s4,16(sp)
ffffffffc0202886:	6aa2                	ld	s5,8(sp)
ffffffffc0202888:	6121                	addi	sp,sp,64
ffffffffc020288a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020288c:	078a                	slli	a5,a5,0x2
ffffffffc020288e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202890:	000a8717          	auipc	a4,0xa8
ffffffffc0202894:	e7873703          	ld	a4,-392(a4) # ffffffffc02aa708 <npage>
ffffffffc0202898:	06e7ff63          	bgeu	a5,a4,ffffffffc0202916 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc020289c:	000a8a97          	auipc	s5,0xa8
ffffffffc02028a0:	e74a8a93          	addi	s5,s5,-396 # ffffffffc02aa710 <pages>
ffffffffc02028a4:	000ab703          	ld	a4,0(s5)
ffffffffc02028a8:	fff80937          	lui	s2,0xfff80
ffffffffc02028ac:	993e                	add	s2,s2,a5
ffffffffc02028ae:	091a                	slli	s2,s2,0x6
ffffffffc02028b0:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02028b2:	01240c63          	beq	s0,s2,ffffffffc02028ca <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02028b6:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcd58bc>
ffffffffc02028ba:	fff7869b          	addiw	a3,a5,-1
ffffffffc02028be:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc02028c2:	c691                	beqz	a3,ffffffffc02028ce <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02028c4:	120a0073          	sfence.vma	s4
}
ffffffffc02028c8:	bf59                	j	ffffffffc020285e <page_insert+0x3a>
ffffffffc02028ca:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02028cc:	bf49                	j	ffffffffc020285e <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02028ce:	100027f3          	csrr	a5,sstatus
ffffffffc02028d2:	8b89                	andi	a5,a5,2
ffffffffc02028d4:	ef91                	bnez	a5,ffffffffc02028f0 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02028d6:	000a8797          	auipc	a5,0xa8
ffffffffc02028da:	e427b783          	ld	a5,-446(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc02028de:	739c                	ld	a5,32(a5)
ffffffffc02028e0:	4585                	li	a1,1
ffffffffc02028e2:	854a                	mv	a0,s2
ffffffffc02028e4:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02028e6:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02028ea:	120a0073          	sfence.vma	s4
ffffffffc02028ee:	bf85                	j	ffffffffc020285e <page_insert+0x3a>
        intr_disable();
ffffffffc02028f0:	8c4fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02028f4:	000a8797          	auipc	a5,0xa8
ffffffffc02028f8:	e247b783          	ld	a5,-476(a5) # ffffffffc02aa718 <pmm_manager>
ffffffffc02028fc:	739c                	ld	a5,32(a5)
ffffffffc02028fe:	4585                	li	a1,1
ffffffffc0202900:	854a                	mv	a0,s2
ffffffffc0202902:	9782                	jalr	a5
        intr_enable();
ffffffffc0202904:	8aafe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202908:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020290c:	120a0073          	sfence.vma	s4
ffffffffc0202910:	b7b9                	j	ffffffffc020285e <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202912:	5571                	li	a0,-4
ffffffffc0202914:	b79d                	j	ffffffffc020287a <page_insert+0x56>
ffffffffc0202916:	f2eff0ef          	jal	ra,ffffffffc0202044 <pa2page.part.0>

ffffffffc020291a <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020291a:	00004797          	auipc	a5,0x4
ffffffffc020291e:	e9e78793          	addi	a5,a5,-354 # ffffffffc02067b8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202922:	638c                	ld	a1,0(a5)
{
ffffffffc0202924:	7159                	addi	sp,sp,-112
ffffffffc0202926:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202928:	00004517          	auipc	a0,0x4
ffffffffc020292c:	fb850513          	addi	a0,a0,-72 # ffffffffc02068e0 <default_pmm_manager+0x128>
    pmm_manager = &default_pmm_manager;
ffffffffc0202930:	000a8b17          	auipc	s6,0xa8
ffffffffc0202934:	de8b0b13          	addi	s6,s6,-536 # ffffffffc02aa718 <pmm_manager>
{
ffffffffc0202938:	f486                	sd	ra,104(sp)
ffffffffc020293a:	e8ca                	sd	s2,80(sp)
ffffffffc020293c:	e4ce                	sd	s3,72(sp)
ffffffffc020293e:	f0a2                	sd	s0,96(sp)
ffffffffc0202940:	eca6                	sd	s1,88(sp)
ffffffffc0202942:	e0d2                	sd	s4,64(sp)
ffffffffc0202944:	fc56                	sd	s5,56(sp)
ffffffffc0202946:	f45e                	sd	s7,40(sp)
ffffffffc0202948:	f062                	sd	s8,32(sp)
ffffffffc020294a:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020294c:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202950:	845fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202954:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202958:	000a8997          	auipc	s3,0xa8
ffffffffc020295c:	dc898993          	addi	s3,s3,-568 # ffffffffc02aa720 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202960:	679c                	ld	a5,8(a5)
ffffffffc0202962:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202964:	57f5                	li	a5,-3
ffffffffc0202966:	07fa                	slli	a5,a5,0x1e
ffffffffc0202968:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc020296c:	82efe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc0202970:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202972:	832fe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc0202976:	200505e3          	beqz	a0,ffffffffc0203380 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020297a:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc020297c:	00004517          	auipc	a0,0x4
ffffffffc0202980:	f9c50513          	addi	a0,a0,-100 # ffffffffc0206918 <default_pmm_manager+0x160>
ffffffffc0202984:	811fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202988:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020298c:	fff40693          	addi	a3,s0,-1
ffffffffc0202990:	864a                	mv	a2,s2
ffffffffc0202992:	85a6                	mv	a1,s1
ffffffffc0202994:	00004517          	auipc	a0,0x4
ffffffffc0202998:	f9c50513          	addi	a0,a0,-100 # ffffffffc0206930 <default_pmm_manager+0x178>
ffffffffc020299c:	ff8fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02029a0:	c8000737          	lui	a4,0xc8000
ffffffffc02029a4:	87a2                	mv	a5,s0
ffffffffc02029a6:	54876163          	bltu	a4,s0,ffffffffc0202ee8 <pmm_init+0x5ce>
ffffffffc02029aa:	757d                	lui	a0,0xfffff
ffffffffc02029ac:	000a9617          	auipc	a2,0xa9
ffffffffc02029b0:	d9760613          	addi	a2,a2,-617 # ffffffffc02ab743 <end+0xfff>
ffffffffc02029b4:	8e69                	and	a2,a2,a0
ffffffffc02029b6:	000a8497          	auipc	s1,0xa8
ffffffffc02029ba:	d5248493          	addi	s1,s1,-686 # ffffffffc02aa708 <npage>
ffffffffc02029be:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02029c2:	000a8b97          	auipc	s7,0xa8
ffffffffc02029c6:	d4eb8b93          	addi	s7,s7,-690 # ffffffffc02aa710 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02029ca:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02029cc:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02029d0:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02029d4:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02029d6:	02f50863          	beq	a0,a5,ffffffffc0202a06 <pmm_init+0xec>
ffffffffc02029da:	4781                	li	a5,0
ffffffffc02029dc:	4585                	li	a1,1
ffffffffc02029de:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02029e2:	00679513          	slli	a0,a5,0x6
ffffffffc02029e6:	9532                	add	a0,a0,a2
ffffffffc02029e8:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd548c4>
ffffffffc02029ec:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02029f0:	6088                	ld	a0,0(s1)
ffffffffc02029f2:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02029f4:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02029f8:	00d50733          	add	a4,a0,a3
ffffffffc02029fc:	fee7e3e3          	bltu	a5,a4,ffffffffc02029e2 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202a00:	071a                	slli	a4,a4,0x6
ffffffffc0202a02:	00e606b3          	add	a3,a2,a4
ffffffffc0202a06:	c02007b7          	lui	a5,0xc0200
ffffffffc0202a0a:	2ef6ece3          	bltu	a3,a5,ffffffffc0203502 <pmm_init+0xbe8>
ffffffffc0202a0e:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202a12:	77fd                	lui	a5,0xfffff
ffffffffc0202a14:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202a16:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202a18:	5086eb63          	bltu	a3,s0,ffffffffc0202f2e <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202a1c:	00004517          	auipc	a0,0x4
ffffffffc0202a20:	f3c50513          	addi	a0,a0,-196 # ffffffffc0206958 <default_pmm_manager+0x1a0>
ffffffffc0202a24:	f70fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202a28:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202a2c:	000a8917          	auipc	s2,0xa8
ffffffffc0202a30:	cd490913          	addi	s2,s2,-812 # ffffffffc02aa700 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202a34:	7b9c                	ld	a5,48(a5)
ffffffffc0202a36:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202a38:	00004517          	auipc	a0,0x4
ffffffffc0202a3c:	f3850513          	addi	a0,a0,-200 # ffffffffc0206970 <default_pmm_manager+0x1b8>
ffffffffc0202a40:	f54fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202a44:	00007697          	auipc	a3,0x7
ffffffffc0202a48:	5bc68693          	addi	a3,a3,1468 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0202a4c:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202a50:	c02007b7          	lui	a5,0xc0200
ffffffffc0202a54:	28f6ebe3          	bltu	a3,a5,ffffffffc02034ea <pmm_init+0xbd0>
ffffffffc0202a58:	0009b783          	ld	a5,0(s3)
ffffffffc0202a5c:	8e9d                	sub	a3,a3,a5
ffffffffc0202a5e:	000a8797          	auipc	a5,0xa8
ffffffffc0202a62:	c8d7bd23          	sd	a3,-870(a5) # ffffffffc02aa6f8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202a66:	100027f3          	csrr	a5,sstatus
ffffffffc0202a6a:	8b89                	andi	a5,a5,2
ffffffffc0202a6c:	4a079763          	bnez	a5,ffffffffc0202f1a <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202a70:	000b3783          	ld	a5,0(s6)
ffffffffc0202a74:	779c                	ld	a5,40(a5)
ffffffffc0202a76:	9782                	jalr	a5
ffffffffc0202a78:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202a7a:	6098                	ld	a4,0(s1)
ffffffffc0202a7c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202a80:	83b1                	srli	a5,a5,0xc
ffffffffc0202a82:	66e7e363          	bltu	a5,a4,ffffffffc02030e8 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202a86:	00093503          	ld	a0,0(s2)
ffffffffc0202a8a:	62050f63          	beqz	a0,ffffffffc02030c8 <pmm_init+0x7ae>
ffffffffc0202a8e:	03451793          	slli	a5,a0,0x34
ffffffffc0202a92:	62079b63          	bnez	a5,ffffffffc02030c8 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202a96:	4601                	li	a2,0
ffffffffc0202a98:	4581                	li	a1,0
ffffffffc0202a9a:	8c3ff0ef          	jal	ra,ffffffffc020235c <get_page>
ffffffffc0202a9e:	60051563          	bnez	a0,ffffffffc02030a8 <pmm_init+0x78e>
ffffffffc0202aa2:	100027f3          	csrr	a5,sstatus
ffffffffc0202aa6:	8b89                	andi	a5,a5,2
ffffffffc0202aa8:	44079e63          	bnez	a5,ffffffffc0202f04 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202aac:	000b3783          	ld	a5,0(s6)
ffffffffc0202ab0:	4505                	li	a0,1
ffffffffc0202ab2:	6f9c                	ld	a5,24(a5)
ffffffffc0202ab4:	9782                	jalr	a5
ffffffffc0202ab6:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202ab8:	00093503          	ld	a0,0(s2)
ffffffffc0202abc:	4681                	li	a3,0
ffffffffc0202abe:	4601                	li	a2,0
ffffffffc0202ac0:	85d2                	mv	a1,s4
ffffffffc0202ac2:	d63ff0ef          	jal	ra,ffffffffc0202824 <page_insert>
ffffffffc0202ac6:	26051ae3          	bnez	a0,ffffffffc020353a <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202aca:	00093503          	ld	a0,0(s2)
ffffffffc0202ace:	4601                	li	a2,0
ffffffffc0202ad0:	4581                	li	a1,0
ffffffffc0202ad2:	e62ff0ef          	jal	ra,ffffffffc0202134 <get_pte>
ffffffffc0202ad6:	240502e3          	beqz	a0,ffffffffc020351a <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0202ada:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202adc:	0017f713          	andi	a4,a5,1
ffffffffc0202ae0:	5a070263          	beqz	a4,ffffffffc0203084 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202ae4:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202ae6:	078a                	slli	a5,a5,0x2
ffffffffc0202ae8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202aea:	58e7fb63          	bgeu	a5,a4,ffffffffc0203080 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202aee:	000bb683          	ld	a3,0(s7)
ffffffffc0202af2:	fff80637          	lui	a2,0xfff80
ffffffffc0202af6:	97b2                	add	a5,a5,a2
ffffffffc0202af8:	079a                	slli	a5,a5,0x6
ffffffffc0202afa:	97b6                	add	a5,a5,a3
ffffffffc0202afc:	14fa17e3          	bne	s4,a5,ffffffffc020344a <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202b00:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
ffffffffc0202b04:	4785                	li	a5,1
ffffffffc0202b06:	12f692e3          	bne	a3,a5,ffffffffc020342a <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202b0a:	00093503          	ld	a0,0(s2)
ffffffffc0202b0e:	77fd                	lui	a5,0xfffff
ffffffffc0202b10:	6114                	ld	a3,0(a0)
ffffffffc0202b12:	068a                	slli	a3,a3,0x2
ffffffffc0202b14:	8efd                	and	a3,a3,a5
ffffffffc0202b16:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202b1a:	0ee67ce3          	bgeu	a2,a4,ffffffffc0203412 <pmm_init+0xaf8>
ffffffffc0202b1e:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202b22:	96e2                	add	a3,a3,s8
ffffffffc0202b24:	0006ba83          	ld	s5,0(a3)
ffffffffc0202b28:	0a8a                	slli	s5,s5,0x2
ffffffffc0202b2a:	00fafab3          	and	s5,s5,a5
ffffffffc0202b2e:	00cad793          	srli	a5,s5,0xc
ffffffffc0202b32:	0ce7f3e3          	bgeu	a5,a4,ffffffffc02033f8 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202b36:	4601                	li	a2,0
ffffffffc0202b38:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202b3a:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202b3c:	df8ff0ef          	jal	ra,ffffffffc0202134 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202b40:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202b42:	55551363          	bne	a0,s5,ffffffffc0203088 <pmm_init+0x76e>
ffffffffc0202b46:	100027f3          	csrr	a5,sstatus
ffffffffc0202b4a:	8b89                	andi	a5,a5,2
ffffffffc0202b4c:	3a079163          	bnez	a5,ffffffffc0202eee <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202b50:	000b3783          	ld	a5,0(s6)
ffffffffc0202b54:	4505                	li	a0,1
ffffffffc0202b56:	6f9c                	ld	a5,24(a5)
ffffffffc0202b58:	9782                	jalr	a5
ffffffffc0202b5a:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202b5c:	00093503          	ld	a0,0(s2)
ffffffffc0202b60:	46d1                	li	a3,20
ffffffffc0202b62:	6605                	lui	a2,0x1
ffffffffc0202b64:	85e2                	mv	a1,s8
ffffffffc0202b66:	cbfff0ef          	jal	ra,ffffffffc0202824 <page_insert>
ffffffffc0202b6a:	060517e3          	bnez	a0,ffffffffc02033d8 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202b6e:	00093503          	ld	a0,0(s2)
ffffffffc0202b72:	4601                	li	a2,0
ffffffffc0202b74:	6585                	lui	a1,0x1
ffffffffc0202b76:	dbeff0ef          	jal	ra,ffffffffc0202134 <get_pte>
ffffffffc0202b7a:	02050fe3          	beqz	a0,ffffffffc02033b8 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0202b7e:	611c                	ld	a5,0(a0)
ffffffffc0202b80:	0107f713          	andi	a4,a5,16
ffffffffc0202b84:	7c070e63          	beqz	a4,ffffffffc0203360 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202b88:	8b91                	andi	a5,a5,4
ffffffffc0202b8a:	7a078b63          	beqz	a5,ffffffffc0203340 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202b8e:	00093503          	ld	a0,0(s2)
ffffffffc0202b92:	611c                	ld	a5,0(a0)
ffffffffc0202b94:	8bc1                	andi	a5,a5,16
ffffffffc0202b96:	78078563          	beqz	a5,ffffffffc0203320 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0202b9a:	000c2703          	lw	a4,0(s8)
ffffffffc0202b9e:	4785                	li	a5,1
ffffffffc0202ba0:	76f71063          	bne	a4,a5,ffffffffc0203300 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202ba4:	4681                	li	a3,0
ffffffffc0202ba6:	6605                	lui	a2,0x1
ffffffffc0202ba8:	85d2                	mv	a1,s4
ffffffffc0202baa:	c7bff0ef          	jal	ra,ffffffffc0202824 <page_insert>
ffffffffc0202bae:	72051963          	bnez	a0,ffffffffc02032e0 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202bb2:	000a2703          	lw	a4,0(s4)
ffffffffc0202bb6:	4789                	li	a5,2
ffffffffc0202bb8:	70f71463          	bne	a4,a5,ffffffffc02032c0 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202bbc:	000c2783          	lw	a5,0(s8)
ffffffffc0202bc0:	6e079063          	bnez	a5,ffffffffc02032a0 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202bc4:	00093503          	ld	a0,0(s2)
ffffffffc0202bc8:	4601                	li	a2,0
ffffffffc0202bca:	6585                	lui	a1,0x1
ffffffffc0202bcc:	d68ff0ef          	jal	ra,ffffffffc0202134 <get_pte>
ffffffffc0202bd0:	6a050863          	beqz	a0,ffffffffc0203280 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202bd4:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202bd6:	00177793          	andi	a5,a4,1
ffffffffc0202bda:	4a078563          	beqz	a5,ffffffffc0203084 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202bde:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202be0:	00271793          	slli	a5,a4,0x2
ffffffffc0202be4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202be6:	48d7fd63          	bgeu	a5,a3,ffffffffc0203080 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202bea:	000bb683          	ld	a3,0(s7)
ffffffffc0202bee:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202bf2:	97d6                	add	a5,a5,s5
ffffffffc0202bf4:	079a                	slli	a5,a5,0x6
ffffffffc0202bf6:	97b6                	add	a5,a5,a3
ffffffffc0202bf8:	66fa1463          	bne	s4,a5,ffffffffc0203260 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202bfc:	8b41                	andi	a4,a4,16
ffffffffc0202bfe:	64071163          	bnez	a4,ffffffffc0203240 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202c02:	00093503          	ld	a0,0(s2)
ffffffffc0202c06:	4581                	li	a1,0
ffffffffc0202c08:	b81ff0ef          	jal	ra,ffffffffc0202788 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202c0c:	000a2c83          	lw	s9,0(s4)
ffffffffc0202c10:	4785                	li	a5,1
ffffffffc0202c12:	60fc9763          	bne	s9,a5,ffffffffc0203220 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202c16:	000c2783          	lw	a5,0(s8)
ffffffffc0202c1a:	5e079363          	bnez	a5,ffffffffc0203200 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202c1e:	00093503          	ld	a0,0(s2)
ffffffffc0202c22:	6585                	lui	a1,0x1
ffffffffc0202c24:	b65ff0ef          	jal	ra,ffffffffc0202788 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202c28:	000a2783          	lw	a5,0(s4)
ffffffffc0202c2c:	52079a63          	bnez	a5,ffffffffc0203160 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202c30:	000c2783          	lw	a5,0(s8)
ffffffffc0202c34:	50079663          	bnez	a5,ffffffffc0203140 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202c38:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c3c:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c3e:	000a3683          	ld	a3,0(s4)
ffffffffc0202c42:	068a                	slli	a3,a3,0x2
ffffffffc0202c44:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c46:	42b6fd63          	bgeu	a3,a1,ffffffffc0203080 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c4a:	000bb503          	ld	a0,0(s7)
ffffffffc0202c4e:	96d6                	add	a3,a3,s5
ffffffffc0202c50:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202c52:	00d507b3          	add	a5,a0,a3
ffffffffc0202c56:	439c                	lw	a5,0(a5)
ffffffffc0202c58:	4d979463          	bne	a5,s9,ffffffffc0203120 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202c5c:	8699                	srai	a3,a3,0x6
ffffffffc0202c5e:	00080637          	lui	a2,0x80
ffffffffc0202c62:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202c64:	00c69713          	slli	a4,a3,0xc
ffffffffc0202c68:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c6a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c6c:	48b77e63          	bgeu	a4,a1,ffffffffc0203108 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202c70:	0009b703          	ld	a4,0(s3)
ffffffffc0202c74:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c76:	629c                	ld	a5,0(a3)
ffffffffc0202c78:	078a                	slli	a5,a5,0x2
ffffffffc0202c7a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c7c:	40b7f263          	bgeu	a5,a1,ffffffffc0203080 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c80:	8f91                	sub	a5,a5,a2
ffffffffc0202c82:	079a                	slli	a5,a5,0x6
ffffffffc0202c84:	953e                	add	a0,a0,a5
ffffffffc0202c86:	100027f3          	csrr	a5,sstatus
ffffffffc0202c8a:	8b89                	andi	a5,a5,2
ffffffffc0202c8c:	30079963          	bnez	a5,ffffffffc0202f9e <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202c90:	000b3783          	ld	a5,0(s6)
ffffffffc0202c94:	4585                	li	a1,1
ffffffffc0202c96:	739c                	ld	a5,32(a5)
ffffffffc0202c98:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c9a:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202c9e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ca0:	078a                	slli	a5,a5,0x2
ffffffffc0202ca2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ca4:	3ce7fe63          	bgeu	a5,a4,ffffffffc0203080 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ca8:	000bb503          	ld	a0,0(s7)
ffffffffc0202cac:	fff80737          	lui	a4,0xfff80
ffffffffc0202cb0:	97ba                	add	a5,a5,a4
ffffffffc0202cb2:	079a                	slli	a5,a5,0x6
ffffffffc0202cb4:	953e                	add	a0,a0,a5
ffffffffc0202cb6:	100027f3          	csrr	a5,sstatus
ffffffffc0202cba:	8b89                	andi	a5,a5,2
ffffffffc0202cbc:	2c079563          	bnez	a5,ffffffffc0202f86 <pmm_init+0x66c>
ffffffffc0202cc0:	000b3783          	ld	a5,0(s6)
ffffffffc0202cc4:	4585                	li	a1,1
ffffffffc0202cc6:	739c                	ld	a5,32(a5)
ffffffffc0202cc8:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202cca:	00093783          	ld	a5,0(s2)
ffffffffc0202cce:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd548bc>
    asm volatile("sfence.vma");
ffffffffc0202cd2:	12000073          	sfence.vma
ffffffffc0202cd6:	100027f3          	csrr	a5,sstatus
ffffffffc0202cda:	8b89                	andi	a5,a5,2
ffffffffc0202cdc:	28079b63          	bnez	a5,ffffffffc0202f72 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ce0:	000b3783          	ld	a5,0(s6)
ffffffffc0202ce4:	779c                	ld	a5,40(a5)
ffffffffc0202ce6:	9782                	jalr	a5
ffffffffc0202ce8:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202cea:	4b441b63          	bne	s0,s4,ffffffffc02031a0 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202cee:	00004517          	auipc	a0,0x4
ffffffffc0202cf2:	faa50513          	addi	a0,a0,-86 # ffffffffc0206c98 <default_pmm_manager+0x4e0>
ffffffffc0202cf6:	c9efd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202cfa:	100027f3          	csrr	a5,sstatus
ffffffffc0202cfe:	8b89                	andi	a5,a5,2
ffffffffc0202d00:	24079f63          	bnez	a5,ffffffffc0202f5e <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d04:	000b3783          	ld	a5,0(s6)
ffffffffc0202d08:	779c                	ld	a5,40(a5)
ffffffffc0202d0a:	9782                	jalr	a5
ffffffffc0202d0c:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202d0e:	6098                	ld	a4,0(s1)
ffffffffc0202d10:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202d14:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202d16:	00c71793          	slli	a5,a4,0xc
ffffffffc0202d1a:	6a05                	lui	s4,0x1
ffffffffc0202d1c:	02f47c63          	bgeu	s0,a5,ffffffffc0202d54 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202d20:	00c45793          	srli	a5,s0,0xc
ffffffffc0202d24:	00093503          	ld	a0,0(s2)
ffffffffc0202d28:	2ee7ff63          	bgeu	a5,a4,ffffffffc0203026 <pmm_init+0x70c>
ffffffffc0202d2c:	0009b583          	ld	a1,0(s3)
ffffffffc0202d30:	4601                	li	a2,0
ffffffffc0202d32:	95a2                	add	a1,a1,s0
ffffffffc0202d34:	c00ff0ef          	jal	ra,ffffffffc0202134 <get_pte>
ffffffffc0202d38:	32050463          	beqz	a0,ffffffffc0203060 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202d3c:	611c                	ld	a5,0(a0)
ffffffffc0202d3e:	078a                	slli	a5,a5,0x2
ffffffffc0202d40:	0157f7b3          	and	a5,a5,s5
ffffffffc0202d44:	2e879e63          	bne	a5,s0,ffffffffc0203040 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202d48:	6098                	ld	a4,0(s1)
ffffffffc0202d4a:	9452                	add	s0,s0,s4
ffffffffc0202d4c:	00c71793          	slli	a5,a4,0xc
ffffffffc0202d50:	fcf468e3          	bltu	s0,a5,ffffffffc0202d20 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202d54:	00093783          	ld	a5,0(s2)
ffffffffc0202d58:	639c                	ld	a5,0(a5)
ffffffffc0202d5a:	42079363          	bnez	a5,ffffffffc0203180 <pmm_init+0x866>
ffffffffc0202d5e:	100027f3          	csrr	a5,sstatus
ffffffffc0202d62:	8b89                	andi	a5,a5,2
ffffffffc0202d64:	24079963          	bnez	a5,ffffffffc0202fb6 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d68:	000b3783          	ld	a5,0(s6)
ffffffffc0202d6c:	4505                	li	a0,1
ffffffffc0202d6e:	6f9c                	ld	a5,24(a5)
ffffffffc0202d70:	9782                	jalr	a5
ffffffffc0202d72:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202d74:	00093503          	ld	a0,0(s2)
ffffffffc0202d78:	4699                	li	a3,6
ffffffffc0202d7a:	10000613          	li	a2,256
ffffffffc0202d7e:	85d2                	mv	a1,s4
ffffffffc0202d80:	aa5ff0ef          	jal	ra,ffffffffc0202824 <page_insert>
ffffffffc0202d84:	44051e63          	bnez	a0,ffffffffc02031e0 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202d88:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
ffffffffc0202d8c:	4785                	li	a5,1
ffffffffc0202d8e:	42f71963          	bne	a4,a5,ffffffffc02031c0 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202d92:	00093503          	ld	a0,0(s2)
ffffffffc0202d96:	6405                	lui	s0,0x1
ffffffffc0202d98:	4699                	li	a3,6
ffffffffc0202d9a:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8aa8>
ffffffffc0202d9e:	85d2                	mv	a1,s4
ffffffffc0202da0:	a85ff0ef          	jal	ra,ffffffffc0202824 <page_insert>
ffffffffc0202da4:	72051363          	bnez	a0,ffffffffc02034ca <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202da8:	000a2703          	lw	a4,0(s4)
ffffffffc0202dac:	4789                	li	a5,2
ffffffffc0202dae:	6ef71e63          	bne	a4,a5,ffffffffc02034aa <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202db2:	00004597          	auipc	a1,0x4
ffffffffc0202db6:	02e58593          	addi	a1,a1,46 # ffffffffc0206de0 <default_pmm_manager+0x628>
ffffffffc0202dba:	10000513          	li	a0,256
ffffffffc0202dbe:	25f020ef          	jal	ra,ffffffffc020581c <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202dc2:	10040593          	addi	a1,s0,256
ffffffffc0202dc6:	10000513          	li	a0,256
ffffffffc0202dca:	265020ef          	jal	ra,ffffffffc020582e <strcmp>
ffffffffc0202dce:	6a051e63          	bnez	a0,ffffffffc020348a <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202dd2:	000bb683          	ld	a3,0(s7)
ffffffffc0202dd6:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202dda:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202ddc:	40da06b3          	sub	a3,s4,a3
ffffffffc0202de0:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202de2:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202de4:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202de6:	8031                	srli	s0,s0,0xc
ffffffffc0202de8:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202dec:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202dee:	30f77d63          	bgeu	a4,a5,ffffffffc0203108 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202df2:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202df6:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202dfa:	96be                	add	a3,a3,a5
ffffffffc0202dfc:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202e00:	1e7020ef          	jal	ra,ffffffffc02057e6 <strlen>
ffffffffc0202e04:	66051363          	bnez	a0,ffffffffc020346a <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202e08:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202e0c:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e0e:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd548bc>
ffffffffc0202e12:	068a                	slli	a3,a3,0x2
ffffffffc0202e14:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202e16:	26f6f563          	bgeu	a3,a5,ffffffffc0203080 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202e1a:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202e1c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202e1e:	2ef47563          	bgeu	s0,a5,ffffffffc0203108 <pmm_init+0x7ee>
ffffffffc0202e22:	0009b403          	ld	s0,0(s3)
ffffffffc0202e26:	9436                	add	s0,s0,a3
ffffffffc0202e28:	100027f3          	csrr	a5,sstatus
ffffffffc0202e2c:	8b89                	andi	a5,a5,2
ffffffffc0202e2e:	1e079163          	bnez	a5,ffffffffc0203010 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202e32:	000b3783          	ld	a5,0(s6)
ffffffffc0202e36:	4585                	li	a1,1
ffffffffc0202e38:	8552                	mv	a0,s4
ffffffffc0202e3a:	739c                	ld	a5,32(a5)
ffffffffc0202e3c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e3e:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202e40:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e42:	078a                	slli	a5,a5,0x2
ffffffffc0202e44:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202e46:	22e7fd63          	bgeu	a5,a4,ffffffffc0203080 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e4a:	000bb503          	ld	a0,0(s7)
ffffffffc0202e4e:	fff80737          	lui	a4,0xfff80
ffffffffc0202e52:	97ba                	add	a5,a5,a4
ffffffffc0202e54:	079a                	slli	a5,a5,0x6
ffffffffc0202e56:	953e                	add	a0,a0,a5
ffffffffc0202e58:	100027f3          	csrr	a5,sstatus
ffffffffc0202e5c:	8b89                	andi	a5,a5,2
ffffffffc0202e5e:	18079d63          	bnez	a5,ffffffffc0202ff8 <pmm_init+0x6de>
ffffffffc0202e62:	000b3783          	ld	a5,0(s6)
ffffffffc0202e66:	4585                	li	a1,1
ffffffffc0202e68:	739c                	ld	a5,32(a5)
ffffffffc0202e6a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e6c:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202e70:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e72:	078a                	slli	a5,a5,0x2
ffffffffc0202e74:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202e76:	20e7f563          	bgeu	a5,a4,ffffffffc0203080 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e7a:	000bb503          	ld	a0,0(s7)
ffffffffc0202e7e:	fff80737          	lui	a4,0xfff80
ffffffffc0202e82:	97ba                	add	a5,a5,a4
ffffffffc0202e84:	079a                	slli	a5,a5,0x6
ffffffffc0202e86:	953e                	add	a0,a0,a5
ffffffffc0202e88:	100027f3          	csrr	a5,sstatus
ffffffffc0202e8c:	8b89                	andi	a5,a5,2
ffffffffc0202e8e:	14079963          	bnez	a5,ffffffffc0202fe0 <pmm_init+0x6c6>
ffffffffc0202e92:	000b3783          	ld	a5,0(s6)
ffffffffc0202e96:	4585                	li	a1,1
ffffffffc0202e98:	739c                	ld	a5,32(a5)
ffffffffc0202e9a:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202e9c:	00093783          	ld	a5,0(s2)
ffffffffc0202ea0:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202ea4:	12000073          	sfence.vma
ffffffffc0202ea8:	100027f3          	csrr	a5,sstatus
ffffffffc0202eac:	8b89                	andi	a5,a5,2
ffffffffc0202eae:	10079f63          	bnez	a5,ffffffffc0202fcc <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202eb2:	000b3783          	ld	a5,0(s6)
ffffffffc0202eb6:	779c                	ld	a5,40(a5)
ffffffffc0202eb8:	9782                	jalr	a5
ffffffffc0202eba:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202ebc:	4c8c1e63          	bne	s8,s0,ffffffffc0203398 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202ec0:	00004517          	auipc	a0,0x4
ffffffffc0202ec4:	f9850513          	addi	a0,a0,-104 # ffffffffc0206e58 <default_pmm_manager+0x6a0>
ffffffffc0202ec8:	accfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202ecc:	7406                	ld	s0,96(sp)
ffffffffc0202ece:	70a6                	ld	ra,104(sp)
ffffffffc0202ed0:	64e6                	ld	s1,88(sp)
ffffffffc0202ed2:	6946                	ld	s2,80(sp)
ffffffffc0202ed4:	69a6                	ld	s3,72(sp)
ffffffffc0202ed6:	6a06                	ld	s4,64(sp)
ffffffffc0202ed8:	7ae2                	ld	s5,56(sp)
ffffffffc0202eda:	7b42                	ld	s6,48(sp)
ffffffffc0202edc:	7ba2                	ld	s7,40(sp)
ffffffffc0202ede:	7c02                	ld	s8,32(sp)
ffffffffc0202ee0:	6ce2                	ld	s9,24(sp)
ffffffffc0202ee2:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202ee4:	f97fe06f          	j	ffffffffc0201e7a <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202ee8:	c80007b7          	lui	a5,0xc8000
ffffffffc0202eec:	bc7d                	j	ffffffffc02029aa <pmm_init+0x90>
        intr_disable();
ffffffffc0202eee:	ac7fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202ef2:	000b3783          	ld	a5,0(s6)
ffffffffc0202ef6:	4505                	li	a0,1
ffffffffc0202ef8:	6f9c                	ld	a5,24(a5)
ffffffffc0202efa:	9782                	jalr	a5
ffffffffc0202efc:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202efe:	ab1fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f02:	b9a9                	j	ffffffffc0202b5c <pmm_init+0x242>
        intr_disable();
ffffffffc0202f04:	ab1fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202f08:	000b3783          	ld	a5,0(s6)
ffffffffc0202f0c:	4505                	li	a0,1
ffffffffc0202f0e:	6f9c                	ld	a5,24(a5)
ffffffffc0202f10:	9782                	jalr	a5
ffffffffc0202f12:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202f14:	a9bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f18:	b645                	j	ffffffffc0202ab8 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202f1a:	a9bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202f1e:	000b3783          	ld	a5,0(s6)
ffffffffc0202f22:	779c                	ld	a5,40(a5)
ffffffffc0202f24:	9782                	jalr	a5
ffffffffc0202f26:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202f28:	a87fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f2c:	b6b9                	j	ffffffffc0202a7a <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202f2e:	6705                	lui	a4,0x1
ffffffffc0202f30:	177d                	addi	a4,a4,-1
ffffffffc0202f32:	96ba                	add	a3,a3,a4
ffffffffc0202f34:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202f36:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202f3a:	14a77363          	bgeu	a4,a0,ffffffffc0203080 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202f3e:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202f42:	fff80537          	lui	a0,0xfff80
ffffffffc0202f46:	972a                	add	a4,a4,a0
ffffffffc0202f48:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202f4a:	8c1d                	sub	s0,s0,a5
ffffffffc0202f4c:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202f50:	00c45593          	srli	a1,s0,0xc
ffffffffc0202f54:	9532                	add	a0,a0,a2
ffffffffc0202f56:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202f58:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202f5c:	b4c1                	j	ffffffffc0202a1c <pmm_init+0x102>
        intr_disable();
ffffffffc0202f5e:	a57fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202f62:	000b3783          	ld	a5,0(s6)
ffffffffc0202f66:	779c                	ld	a5,40(a5)
ffffffffc0202f68:	9782                	jalr	a5
ffffffffc0202f6a:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202f6c:	a43fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f70:	bb79                	j	ffffffffc0202d0e <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202f72:	a43fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202f76:	000b3783          	ld	a5,0(s6)
ffffffffc0202f7a:	779c                	ld	a5,40(a5)
ffffffffc0202f7c:	9782                	jalr	a5
ffffffffc0202f7e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202f80:	a2ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f84:	b39d                	j	ffffffffc0202cea <pmm_init+0x3d0>
ffffffffc0202f86:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202f88:	a2dfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202f8c:	000b3783          	ld	a5,0(s6)
ffffffffc0202f90:	6522                	ld	a0,8(sp)
ffffffffc0202f92:	4585                	li	a1,1
ffffffffc0202f94:	739c                	ld	a5,32(a5)
ffffffffc0202f96:	9782                	jalr	a5
        intr_enable();
ffffffffc0202f98:	a17fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202f9c:	b33d                	j	ffffffffc0202cca <pmm_init+0x3b0>
ffffffffc0202f9e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202fa0:	a15fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202fa4:	000b3783          	ld	a5,0(s6)
ffffffffc0202fa8:	6522                	ld	a0,8(sp)
ffffffffc0202faa:	4585                	li	a1,1
ffffffffc0202fac:	739c                	ld	a5,32(a5)
ffffffffc0202fae:	9782                	jalr	a5
        intr_enable();
ffffffffc0202fb0:	9fffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202fb4:	b1dd                	j	ffffffffc0202c9a <pmm_init+0x380>
        intr_disable();
ffffffffc0202fb6:	9fffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202fba:	000b3783          	ld	a5,0(s6)
ffffffffc0202fbe:	4505                	li	a0,1
ffffffffc0202fc0:	6f9c                	ld	a5,24(a5)
ffffffffc0202fc2:	9782                	jalr	a5
ffffffffc0202fc4:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202fc6:	9e9fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202fca:	b36d                	j	ffffffffc0202d74 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202fcc:	9e9fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202fd0:	000b3783          	ld	a5,0(s6)
ffffffffc0202fd4:	779c                	ld	a5,40(a5)
ffffffffc0202fd6:	9782                	jalr	a5
ffffffffc0202fd8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202fda:	9d5fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202fde:	bdf9                	j	ffffffffc0202ebc <pmm_init+0x5a2>
ffffffffc0202fe0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202fe2:	9d3fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202fe6:	000b3783          	ld	a5,0(s6)
ffffffffc0202fea:	6522                	ld	a0,8(sp)
ffffffffc0202fec:	4585                	li	a1,1
ffffffffc0202fee:	739c                	ld	a5,32(a5)
ffffffffc0202ff0:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ff2:	9bdfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ff6:	b55d                	j	ffffffffc0202e9c <pmm_init+0x582>
ffffffffc0202ff8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ffa:	9bbfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202ffe:	000b3783          	ld	a5,0(s6)
ffffffffc0203002:	6522                	ld	a0,8(sp)
ffffffffc0203004:	4585                	li	a1,1
ffffffffc0203006:	739c                	ld	a5,32(a5)
ffffffffc0203008:	9782                	jalr	a5
        intr_enable();
ffffffffc020300a:	9a5fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020300e:	bdb9                	j	ffffffffc0202e6c <pmm_init+0x552>
        intr_disable();
ffffffffc0203010:	9a5fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203014:	000b3783          	ld	a5,0(s6)
ffffffffc0203018:	4585                	li	a1,1
ffffffffc020301a:	8552                	mv	a0,s4
ffffffffc020301c:	739c                	ld	a5,32(a5)
ffffffffc020301e:	9782                	jalr	a5
        intr_enable();
ffffffffc0203020:	98ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203024:	bd29                	j	ffffffffc0202e3e <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0203026:	86a2                	mv	a3,s0
ffffffffc0203028:	00003617          	auipc	a2,0x3
ffffffffc020302c:	31860613          	addi	a2,a2,792 # ffffffffc0206340 <commands+0x820>
ffffffffc0203030:	25500593          	li	a1,597
ffffffffc0203034:	00004517          	auipc	a0,0x4
ffffffffc0203038:	85450513          	addi	a0,a0,-1964 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020303c:	c52fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0203040:	00004697          	auipc	a3,0x4
ffffffffc0203044:	cb868693          	addi	a3,a3,-840 # ffffffffc0206cf8 <default_pmm_manager+0x540>
ffffffffc0203048:	00003617          	auipc	a2,0x3
ffffffffc020304c:	3c060613          	addi	a2,a2,960 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203050:	25600593          	li	a1,598
ffffffffc0203054:	00004517          	auipc	a0,0x4
ffffffffc0203058:	83450513          	addi	a0,a0,-1996 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020305c:	c32fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0203060:	00004697          	auipc	a3,0x4
ffffffffc0203064:	c5868693          	addi	a3,a3,-936 # ffffffffc0206cb8 <default_pmm_manager+0x500>
ffffffffc0203068:	00003617          	auipc	a2,0x3
ffffffffc020306c:	3a060613          	addi	a2,a2,928 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203070:	25500593          	li	a1,597
ffffffffc0203074:	00004517          	auipc	a0,0x4
ffffffffc0203078:	81450513          	addi	a0,a0,-2028 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020307c:	c12fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203080:	fc5fe0ef          	jal	ra,ffffffffc0202044 <pa2page.part.0>
ffffffffc0203084:	fddfe0ef          	jal	ra,ffffffffc0202060 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0203088:	00004697          	auipc	a3,0x4
ffffffffc020308c:	a2868693          	addi	a3,a3,-1496 # ffffffffc0206ab0 <default_pmm_manager+0x2f8>
ffffffffc0203090:	00003617          	auipc	a2,0x3
ffffffffc0203094:	37860613          	addi	a2,a2,888 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203098:	22500593          	li	a1,549
ffffffffc020309c:	00003517          	auipc	a0,0x3
ffffffffc02030a0:	7ec50513          	addi	a0,a0,2028 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02030a4:	beafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02030a8:	00004697          	auipc	a3,0x4
ffffffffc02030ac:	94868693          	addi	a3,a3,-1720 # ffffffffc02069f0 <default_pmm_manager+0x238>
ffffffffc02030b0:	00003617          	auipc	a2,0x3
ffffffffc02030b4:	35860613          	addi	a2,a2,856 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02030b8:	21800593          	li	a1,536
ffffffffc02030bc:	00003517          	auipc	a0,0x3
ffffffffc02030c0:	7cc50513          	addi	a0,a0,1996 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02030c4:	bcafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02030c8:	00004697          	auipc	a3,0x4
ffffffffc02030cc:	8e868693          	addi	a3,a3,-1816 # ffffffffc02069b0 <default_pmm_manager+0x1f8>
ffffffffc02030d0:	00003617          	auipc	a2,0x3
ffffffffc02030d4:	33860613          	addi	a2,a2,824 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02030d8:	21700593          	li	a1,535
ffffffffc02030dc:	00003517          	auipc	a0,0x3
ffffffffc02030e0:	7ac50513          	addi	a0,a0,1964 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02030e4:	baafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02030e8:	00004697          	auipc	a3,0x4
ffffffffc02030ec:	8a868693          	addi	a3,a3,-1880 # ffffffffc0206990 <default_pmm_manager+0x1d8>
ffffffffc02030f0:	00003617          	auipc	a2,0x3
ffffffffc02030f4:	31860613          	addi	a2,a2,792 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02030f8:	21600593          	li	a1,534
ffffffffc02030fc:	00003517          	auipc	a0,0x3
ffffffffc0203100:	78c50513          	addi	a0,a0,1932 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc0203104:	b8afd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0203108:	00003617          	auipc	a2,0x3
ffffffffc020310c:	23860613          	addi	a2,a2,568 # ffffffffc0206340 <commands+0x820>
ffffffffc0203110:	07100593          	li	a1,113
ffffffffc0203114:	00003517          	auipc	a0,0x3
ffffffffc0203118:	1e450513          	addi	a0,a0,484 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc020311c:	b72fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0203120:	00004697          	auipc	a3,0x4
ffffffffc0203124:	b2068693          	addi	a3,a3,-1248 # ffffffffc0206c40 <default_pmm_manager+0x488>
ffffffffc0203128:	00003617          	auipc	a2,0x3
ffffffffc020312c:	2e060613          	addi	a2,a2,736 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203130:	23e00593          	li	a1,574
ffffffffc0203134:	00003517          	auipc	a0,0x3
ffffffffc0203138:	75450513          	addi	a0,a0,1876 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020313c:	b52fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203140:	00004697          	auipc	a3,0x4
ffffffffc0203144:	ab868693          	addi	a3,a3,-1352 # ffffffffc0206bf8 <default_pmm_manager+0x440>
ffffffffc0203148:	00003617          	auipc	a2,0x3
ffffffffc020314c:	2c060613          	addi	a2,a2,704 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203150:	23c00593          	li	a1,572
ffffffffc0203154:	00003517          	auipc	a0,0x3
ffffffffc0203158:	73450513          	addi	a0,a0,1844 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020315c:	b32fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0203160:	00004697          	auipc	a3,0x4
ffffffffc0203164:	ac868693          	addi	a3,a3,-1336 # ffffffffc0206c28 <default_pmm_manager+0x470>
ffffffffc0203168:	00003617          	auipc	a2,0x3
ffffffffc020316c:	2a060613          	addi	a2,a2,672 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203170:	23b00593          	li	a1,571
ffffffffc0203174:	00003517          	auipc	a0,0x3
ffffffffc0203178:	71450513          	addi	a0,a0,1812 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020317c:	b12fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0203180:	00004697          	auipc	a3,0x4
ffffffffc0203184:	b9068693          	addi	a3,a3,-1136 # ffffffffc0206d10 <default_pmm_manager+0x558>
ffffffffc0203188:	00003617          	auipc	a2,0x3
ffffffffc020318c:	28060613          	addi	a2,a2,640 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203190:	25900593          	li	a1,601
ffffffffc0203194:	00003517          	auipc	a0,0x3
ffffffffc0203198:	6f450513          	addi	a0,a0,1780 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020319c:	af2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02031a0:	00004697          	auipc	a3,0x4
ffffffffc02031a4:	ad068693          	addi	a3,a3,-1328 # ffffffffc0206c70 <default_pmm_manager+0x4b8>
ffffffffc02031a8:	00003617          	auipc	a2,0x3
ffffffffc02031ac:	26060613          	addi	a2,a2,608 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02031b0:	24600593          	li	a1,582
ffffffffc02031b4:	00003517          	auipc	a0,0x3
ffffffffc02031b8:	6d450513          	addi	a0,a0,1748 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02031bc:	ad2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc02031c0:	00004697          	auipc	a3,0x4
ffffffffc02031c4:	ba868693          	addi	a3,a3,-1112 # ffffffffc0206d68 <default_pmm_manager+0x5b0>
ffffffffc02031c8:	00003617          	auipc	a2,0x3
ffffffffc02031cc:	24060613          	addi	a2,a2,576 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02031d0:	25e00593          	li	a1,606
ffffffffc02031d4:	00003517          	auipc	a0,0x3
ffffffffc02031d8:	6b450513          	addi	a0,a0,1716 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02031dc:	ab2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02031e0:	00004697          	auipc	a3,0x4
ffffffffc02031e4:	b4868693          	addi	a3,a3,-1208 # ffffffffc0206d28 <default_pmm_manager+0x570>
ffffffffc02031e8:	00003617          	auipc	a2,0x3
ffffffffc02031ec:	22060613          	addi	a2,a2,544 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02031f0:	25d00593          	li	a1,605
ffffffffc02031f4:	00003517          	auipc	a0,0x3
ffffffffc02031f8:	69450513          	addi	a0,a0,1684 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02031fc:	a92fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203200:	00004697          	auipc	a3,0x4
ffffffffc0203204:	9f868693          	addi	a3,a3,-1544 # ffffffffc0206bf8 <default_pmm_manager+0x440>
ffffffffc0203208:	00003617          	auipc	a2,0x3
ffffffffc020320c:	20060613          	addi	a2,a2,512 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203210:	23800593          	li	a1,568
ffffffffc0203214:	00003517          	auipc	a0,0x3
ffffffffc0203218:	67450513          	addi	a0,a0,1652 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020321c:	a72fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203220:	00004697          	auipc	a3,0x4
ffffffffc0203224:	87868693          	addi	a3,a3,-1928 # ffffffffc0206a98 <default_pmm_manager+0x2e0>
ffffffffc0203228:	00003617          	auipc	a2,0x3
ffffffffc020322c:	1e060613          	addi	a2,a2,480 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203230:	23700593          	li	a1,567
ffffffffc0203234:	00003517          	auipc	a0,0x3
ffffffffc0203238:	65450513          	addi	a0,a0,1620 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020323c:	a52fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203240:	00004697          	auipc	a3,0x4
ffffffffc0203244:	9d068693          	addi	a3,a3,-1584 # ffffffffc0206c10 <default_pmm_manager+0x458>
ffffffffc0203248:	00003617          	auipc	a2,0x3
ffffffffc020324c:	1c060613          	addi	a2,a2,448 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203250:	23400593          	li	a1,564
ffffffffc0203254:	00003517          	auipc	a0,0x3
ffffffffc0203258:	63450513          	addi	a0,a0,1588 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020325c:	a32fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203260:	00004697          	auipc	a3,0x4
ffffffffc0203264:	82068693          	addi	a3,a3,-2016 # ffffffffc0206a80 <default_pmm_manager+0x2c8>
ffffffffc0203268:	00003617          	auipc	a2,0x3
ffffffffc020326c:	1a060613          	addi	a2,a2,416 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203270:	23300593          	li	a1,563
ffffffffc0203274:	00003517          	auipc	a0,0x3
ffffffffc0203278:	61450513          	addi	a0,a0,1556 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020327c:	a12fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203280:	00004697          	auipc	a3,0x4
ffffffffc0203284:	8a068693          	addi	a3,a3,-1888 # ffffffffc0206b20 <default_pmm_manager+0x368>
ffffffffc0203288:	00003617          	auipc	a2,0x3
ffffffffc020328c:	18060613          	addi	a2,a2,384 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203290:	23200593          	li	a1,562
ffffffffc0203294:	00003517          	auipc	a0,0x3
ffffffffc0203298:	5f450513          	addi	a0,a0,1524 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020329c:	9f2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02032a0:	00004697          	auipc	a3,0x4
ffffffffc02032a4:	95868693          	addi	a3,a3,-1704 # ffffffffc0206bf8 <default_pmm_manager+0x440>
ffffffffc02032a8:	00003617          	auipc	a2,0x3
ffffffffc02032ac:	16060613          	addi	a2,a2,352 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02032b0:	23100593          	li	a1,561
ffffffffc02032b4:	00003517          	auipc	a0,0x3
ffffffffc02032b8:	5d450513          	addi	a0,a0,1492 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02032bc:	9d2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02032c0:	00004697          	auipc	a3,0x4
ffffffffc02032c4:	92068693          	addi	a3,a3,-1760 # ffffffffc0206be0 <default_pmm_manager+0x428>
ffffffffc02032c8:	00003617          	auipc	a2,0x3
ffffffffc02032cc:	14060613          	addi	a2,a2,320 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02032d0:	23000593          	li	a1,560
ffffffffc02032d4:	00003517          	auipc	a0,0x3
ffffffffc02032d8:	5b450513          	addi	a0,a0,1460 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02032dc:	9b2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02032e0:	00004697          	auipc	a3,0x4
ffffffffc02032e4:	8d068693          	addi	a3,a3,-1840 # ffffffffc0206bb0 <default_pmm_manager+0x3f8>
ffffffffc02032e8:	00003617          	auipc	a2,0x3
ffffffffc02032ec:	12060613          	addi	a2,a2,288 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02032f0:	22f00593          	li	a1,559
ffffffffc02032f4:	00003517          	auipc	a0,0x3
ffffffffc02032f8:	59450513          	addi	a0,a0,1428 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02032fc:	992fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203300:	00004697          	auipc	a3,0x4
ffffffffc0203304:	89868693          	addi	a3,a3,-1896 # ffffffffc0206b98 <default_pmm_manager+0x3e0>
ffffffffc0203308:	00003617          	auipc	a2,0x3
ffffffffc020330c:	10060613          	addi	a2,a2,256 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203310:	22d00593          	li	a1,557
ffffffffc0203314:	00003517          	auipc	a0,0x3
ffffffffc0203318:	57450513          	addi	a0,a0,1396 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020331c:	972fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203320:	00004697          	auipc	a3,0x4
ffffffffc0203324:	85868693          	addi	a3,a3,-1960 # ffffffffc0206b78 <default_pmm_manager+0x3c0>
ffffffffc0203328:	00003617          	auipc	a2,0x3
ffffffffc020332c:	0e060613          	addi	a2,a2,224 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203330:	22c00593          	li	a1,556
ffffffffc0203334:	00003517          	auipc	a0,0x3
ffffffffc0203338:	55450513          	addi	a0,a0,1364 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020333c:	952fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203340:	00004697          	auipc	a3,0x4
ffffffffc0203344:	82868693          	addi	a3,a3,-2008 # ffffffffc0206b68 <default_pmm_manager+0x3b0>
ffffffffc0203348:	00003617          	auipc	a2,0x3
ffffffffc020334c:	0c060613          	addi	a2,a2,192 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203350:	22b00593          	li	a1,555
ffffffffc0203354:	00003517          	auipc	a0,0x3
ffffffffc0203358:	53450513          	addi	a0,a0,1332 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020335c:	932fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203360:	00003697          	auipc	a3,0x3
ffffffffc0203364:	7f868693          	addi	a3,a3,2040 # ffffffffc0206b58 <default_pmm_manager+0x3a0>
ffffffffc0203368:	00003617          	auipc	a2,0x3
ffffffffc020336c:	0a060613          	addi	a2,a2,160 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203370:	22a00593          	li	a1,554
ffffffffc0203374:	00003517          	auipc	a0,0x3
ffffffffc0203378:	51450513          	addi	a0,a0,1300 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020337c:	912fd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc0203380:	00003617          	auipc	a2,0x3
ffffffffc0203384:	57860613          	addi	a2,a2,1400 # ffffffffc02068f8 <default_pmm_manager+0x140>
ffffffffc0203388:	06500593          	li	a1,101
ffffffffc020338c:	00003517          	auipc	a0,0x3
ffffffffc0203390:	4fc50513          	addi	a0,a0,1276 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc0203394:	8fafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203398:	00004697          	auipc	a3,0x4
ffffffffc020339c:	8d868693          	addi	a3,a3,-1832 # ffffffffc0206c70 <default_pmm_manager+0x4b8>
ffffffffc02033a0:	00003617          	auipc	a2,0x3
ffffffffc02033a4:	06860613          	addi	a2,a2,104 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02033a8:	27000593          	li	a1,624
ffffffffc02033ac:	00003517          	auipc	a0,0x3
ffffffffc02033b0:	4dc50513          	addi	a0,a0,1244 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02033b4:	8dafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02033b8:	00003697          	auipc	a3,0x3
ffffffffc02033bc:	76868693          	addi	a3,a3,1896 # ffffffffc0206b20 <default_pmm_manager+0x368>
ffffffffc02033c0:	00003617          	auipc	a2,0x3
ffffffffc02033c4:	04860613          	addi	a2,a2,72 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02033c8:	22900593          	li	a1,553
ffffffffc02033cc:	00003517          	auipc	a0,0x3
ffffffffc02033d0:	4bc50513          	addi	a0,a0,1212 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02033d4:	8bafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02033d8:	00003697          	auipc	a3,0x3
ffffffffc02033dc:	70868693          	addi	a3,a3,1800 # ffffffffc0206ae0 <default_pmm_manager+0x328>
ffffffffc02033e0:	00003617          	auipc	a2,0x3
ffffffffc02033e4:	02860613          	addi	a2,a2,40 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02033e8:	22800593          	li	a1,552
ffffffffc02033ec:	00003517          	auipc	a0,0x3
ffffffffc02033f0:	49c50513          	addi	a0,a0,1180 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02033f4:	89afd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02033f8:	86d6                	mv	a3,s5
ffffffffc02033fa:	00003617          	auipc	a2,0x3
ffffffffc02033fe:	f4660613          	addi	a2,a2,-186 # ffffffffc0206340 <commands+0x820>
ffffffffc0203402:	22400593          	li	a1,548
ffffffffc0203406:	00003517          	auipc	a0,0x3
ffffffffc020340a:	48250513          	addi	a0,a0,1154 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc020340e:	880fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203412:	00003617          	auipc	a2,0x3
ffffffffc0203416:	f2e60613          	addi	a2,a2,-210 # ffffffffc0206340 <commands+0x820>
ffffffffc020341a:	22300593          	li	a1,547
ffffffffc020341e:	00003517          	auipc	a0,0x3
ffffffffc0203422:	46a50513          	addi	a0,a0,1130 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc0203426:	868fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020342a:	00003697          	auipc	a3,0x3
ffffffffc020342e:	66e68693          	addi	a3,a3,1646 # ffffffffc0206a98 <default_pmm_manager+0x2e0>
ffffffffc0203432:	00003617          	auipc	a2,0x3
ffffffffc0203436:	fd660613          	addi	a2,a2,-42 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020343a:	22100593          	li	a1,545
ffffffffc020343e:	00003517          	auipc	a0,0x3
ffffffffc0203442:	44a50513          	addi	a0,a0,1098 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc0203446:	848fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020344a:	00003697          	auipc	a3,0x3
ffffffffc020344e:	63668693          	addi	a3,a3,1590 # ffffffffc0206a80 <default_pmm_manager+0x2c8>
ffffffffc0203452:	00003617          	auipc	a2,0x3
ffffffffc0203456:	fb660613          	addi	a2,a2,-74 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020345a:	22000593          	li	a1,544
ffffffffc020345e:	00003517          	auipc	a0,0x3
ffffffffc0203462:	42a50513          	addi	a0,a0,1066 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc0203466:	828fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020346a:	00004697          	auipc	a3,0x4
ffffffffc020346e:	9c668693          	addi	a3,a3,-1594 # ffffffffc0206e30 <default_pmm_manager+0x678>
ffffffffc0203472:	00003617          	auipc	a2,0x3
ffffffffc0203476:	f9660613          	addi	a2,a2,-106 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020347a:	26700593          	li	a1,615
ffffffffc020347e:	00003517          	auipc	a0,0x3
ffffffffc0203482:	40a50513          	addi	a0,a0,1034 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc0203486:	808fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020348a:	00004697          	auipc	a3,0x4
ffffffffc020348e:	96e68693          	addi	a3,a3,-1682 # ffffffffc0206df8 <default_pmm_manager+0x640>
ffffffffc0203492:	00003617          	auipc	a2,0x3
ffffffffc0203496:	f7660613          	addi	a2,a2,-138 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020349a:	26400593          	li	a1,612
ffffffffc020349e:	00003517          	auipc	a0,0x3
ffffffffc02034a2:	3ea50513          	addi	a0,a0,1002 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02034a6:	fe9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc02034aa:	00004697          	auipc	a3,0x4
ffffffffc02034ae:	91e68693          	addi	a3,a3,-1762 # ffffffffc0206dc8 <default_pmm_manager+0x610>
ffffffffc02034b2:	00003617          	auipc	a2,0x3
ffffffffc02034b6:	f5660613          	addi	a2,a2,-170 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02034ba:	26000593          	li	a1,608
ffffffffc02034be:	00003517          	auipc	a0,0x3
ffffffffc02034c2:	3ca50513          	addi	a0,a0,970 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02034c6:	fc9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02034ca:	00004697          	auipc	a3,0x4
ffffffffc02034ce:	8b668693          	addi	a3,a3,-1866 # ffffffffc0206d80 <default_pmm_manager+0x5c8>
ffffffffc02034d2:	00003617          	auipc	a2,0x3
ffffffffc02034d6:	f3660613          	addi	a2,a2,-202 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02034da:	25f00593          	li	a1,607
ffffffffc02034de:	00003517          	auipc	a0,0x3
ffffffffc02034e2:	3aa50513          	addi	a0,a0,938 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02034e6:	fa9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02034ea:	00003617          	auipc	a2,0x3
ffffffffc02034ee:	37660613          	addi	a2,a2,886 # ffffffffc0206860 <default_pmm_manager+0xa8>
ffffffffc02034f2:	0c900593          	li	a1,201
ffffffffc02034f6:	00003517          	auipc	a0,0x3
ffffffffc02034fa:	39250513          	addi	a0,a0,914 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02034fe:	f91fc0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203502:	00003617          	auipc	a2,0x3
ffffffffc0203506:	35e60613          	addi	a2,a2,862 # ffffffffc0206860 <default_pmm_manager+0xa8>
ffffffffc020350a:	08100593          	li	a1,129
ffffffffc020350e:	00003517          	auipc	a0,0x3
ffffffffc0203512:	37a50513          	addi	a0,a0,890 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc0203516:	f79fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020351a:	00003697          	auipc	a3,0x3
ffffffffc020351e:	53668693          	addi	a3,a3,1334 # ffffffffc0206a50 <default_pmm_manager+0x298>
ffffffffc0203522:	00003617          	auipc	a2,0x3
ffffffffc0203526:	ee660613          	addi	a2,a2,-282 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020352a:	21f00593          	li	a1,543
ffffffffc020352e:	00003517          	auipc	a0,0x3
ffffffffc0203532:	35a50513          	addi	a0,a0,858 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc0203536:	f59fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020353a:	00003697          	auipc	a3,0x3
ffffffffc020353e:	4e668693          	addi	a3,a3,1254 # ffffffffc0206a20 <default_pmm_manager+0x268>
ffffffffc0203542:	00003617          	auipc	a2,0x3
ffffffffc0203546:	ec660613          	addi	a2,a2,-314 # ffffffffc0206408 <commands+0x8e8>
ffffffffc020354a:	21c00593          	li	a1,540
ffffffffc020354e:	00003517          	auipc	a0,0x3
ffffffffc0203552:	33a50513          	addi	a0,a0,826 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc0203556:	f39fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020355a <copy_range>:
{
ffffffffc020355a:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020355c:	00d667b3          	or	a5,a2,a3
{
ffffffffc0203560:	e03a                	sd	a4,0(sp)
ffffffffc0203562:	fc86                	sd	ra,120(sp)
ffffffffc0203564:	f8a2                	sd	s0,112(sp)
ffffffffc0203566:	f4a6                	sd	s1,104(sp)
ffffffffc0203568:	f0ca                	sd	s2,96(sp)
ffffffffc020356a:	ecce                	sd	s3,88(sp)
ffffffffc020356c:	e8d2                	sd	s4,80(sp)
ffffffffc020356e:	e4d6                	sd	s5,72(sp)
ffffffffc0203570:	e0da                	sd	s6,64(sp)
ffffffffc0203572:	fc5e                	sd	s7,56(sp)
ffffffffc0203574:	f862                	sd	s8,48(sp)
ffffffffc0203576:	f466                	sd	s9,40(sp)
ffffffffc0203578:	f06a                	sd	s10,32(sp)
ffffffffc020357a:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020357c:	03479713          	slli	a4,a5,0x34
ffffffffc0203580:	24071b63          	bnez	a4,ffffffffc02037d6 <copy_range+0x27c>
    assert(USER_ACCESS(start, end));
ffffffffc0203584:	002007b7          	lui	a5,0x200
ffffffffc0203588:	22f66763          	bltu	a2,a5,ffffffffc02037b6 <copy_range+0x25c>
ffffffffc020358c:	84b6                	mv	s1,a3
ffffffffc020358e:	22d67463          	bgeu	a2,a3,ffffffffc02037b6 <copy_range+0x25c>
ffffffffc0203592:	4785                	li	a5,1
ffffffffc0203594:	6705                	lui	a4,0x1
ffffffffc0203596:	07fe                	slli	a5,a5,0x1f
ffffffffc0203598:	00e60bb3          	add	s7,a2,a4
ffffffffc020359c:	20d7ed63          	bltu	a5,a3,ffffffffc02037b6 <copy_range+0x25c>
ffffffffc02035a0:	5b7d                	li	s6,-1
ffffffffc02035a2:	00cb5793          	srli	a5,s6,0xc
ffffffffc02035a6:	8a2a                	mv	s4,a0
ffffffffc02035a8:	842e                	mv	s0,a1
ffffffffc02035aa:	79fd                	lui	s3,0xfffff
    if (PPN(pa) >= npage)
ffffffffc02035ac:	000a7c97          	auipc	s9,0xa7
ffffffffc02035b0:	15cc8c93          	addi	s9,s9,348 # ffffffffc02aa708 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02035b4:	000a7c17          	auipc	s8,0xa7
ffffffffc02035b8:	15cc0c13          	addi	s8,s8,348 # ffffffffc02aa710 <pages>
    return KADDR(page2pa(page));
ffffffffc02035bc:	e43e                	sd	a5,8(sp)
        page = pmm_manager->alloc_pages(n);
ffffffffc02035be:	000a7d17          	auipc	s10,0xa7
ffffffffc02035c2:	15ad0d13          	addi	s10,s10,346 # ffffffffc02aa718 <pmm_manager>
ffffffffc02035c6:	a031                	j	ffffffffc02035d2 <copy_range+0x78>
    } while (start != 0 && start < end);
ffffffffc02035c8:	6785                	lui	a5,0x1
ffffffffc02035ca:	97de                	add	a5,a5,s7
ffffffffc02035cc:	169bf463          	bgeu	s7,s1,ffffffffc0203734 <copy_range+0x1da>
ffffffffc02035d0:	8bbe                	mv	s7,a5
ffffffffc02035d2:	013b8b33          	add	s6,s7,s3
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc02035d6:	4601                	li	a2,0
ffffffffc02035d8:	85da                	mv	a1,s6
ffffffffc02035da:	8522                	mv	a0,s0
ffffffffc02035dc:	b59fe0ef          	jal	ra,ffffffffc0202134 <get_pte>
ffffffffc02035e0:	8aaa                	mv	s5,a0
        if (ptep == NULL)
ffffffffc02035e2:	d17d                	beqz	a0,ffffffffc02035c8 <copy_range+0x6e>
        if (*ptep & PTE_V) // 源页面有效
ffffffffc02035e4:	6114                	ld	a3,0(a0)
ffffffffc02035e6:	8a85                	andi	a3,a3,1
ffffffffc02035e8:	d2e5                	beqz	a3,ffffffffc02035c8 <copy_range+0x6e>
            nptep = get_pte(to, start, 1);
ffffffffc02035ea:	4605                	li	a2,1
ffffffffc02035ec:	85da                	mv	a1,s6
ffffffffc02035ee:	8552                	mv	a0,s4
ffffffffc02035f0:	b45fe0ef          	jal	ra,ffffffffc0202134 <get_pte>
            if (nptep == NULL)
ffffffffc02035f4:	14050263          	beqz	a0,ffffffffc0203738 <copy_range+0x1de>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02035f8:	000ab683          	ld	a3,0(s5)
            if (share) {
ffffffffc02035fc:	6782                	ld	a5,0(sp)
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02035fe:	0006891b          	sext.w	s2,a3
            if (share) {
ffffffffc0203602:	c7bd                	beqz	a5,ffffffffc0203670 <copy_range+0x116>
    if (!(pte & PTE_V))
ffffffffc0203604:	0016f793          	andi	a5,a3,1
ffffffffc0203608:	18078863          	beqz	a5,ffffffffc0203798 <copy_range+0x23e>
    if (PPN(pa) >= npage)
ffffffffc020360c:	000cb783          	ld	a5,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203610:	068a                	slli	a3,a3,0x2
ffffffffc0203612:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0203614:	18f6f063          	bgeu	a3,a5,ffffffffc0203794 <copy_range+0x23a>
    return &pages[PPN(pa) - nbase];
ffffffffc0203618:	000c3583          	ld	a1,0(s8)
ffffffffc020361c:	fff807b7          	lui	a5,0xfff80
ffffffffc0203620:	96be                	add	a3,a3,a5
ffffffffc0203622:	069a                	slli	a3,a3,0x6
ffffffffc0203624:	00d58ab3          	add	s5,a1,a3
                assert(page != NULL);
ffffffffc0203628:	140a8663          	beqz	s5,ffffffffc0203774 <copy_range+0x21a>
                int ret = page_insert(to, page, start, perm & (~PTE_W));
ffffffffc020362c:	01b97913          	andi	s2,s2,27
ffffffffc0203630:	86ca                	mv	a3,s2
ffffffffc0203632:	865a                	mv	a2,s6
ffffffffc0203634:	85d6                	mv	a1,s5
ffffffffc0203636:	8552                	mv	a0,s4
ffffffffc0203638:	9ecff0ef          	jal	ra,ffffffffc0202824 <page_insert>
ffffffffc020363c:	87aa                	mv	a5,a0
                if (ret != 0) {
ffffffffc020363e:	e909                	bnez	a0,ffffffffc0203650 <copy_range+0xf6>
                ret = page_insert(from, page, start, perm & (~PTE_W));
ffffffffc0203640:	86ca                	mv	a3,s2
ffffffffc0203642:	865a                	mv	a2,s6
ffffffffc0203644:	85d6                	mv	a1,s5
ffffffffc0203646:	8522                	mv	a0,s0
ffffffffc0203648:	9dcff0ef          	jal	ra,ffffffffc0202824 <page_insert>
ffffffffc020364c:	87aa                	mv	a5,a0
                if (ret != 0) {
ffffffffc020364e:	dd2d                	beqz	a0,ffffffffc02035c8 <copy_range+0x6e>
}
ffffffffc0203650:	70e6                	ld	ra,120(sp)
ffffffffc0203652:	7446                	ld	s0,112(sp)
ffffffffc0203654:	74a6                	ld	s1,104(sp)
ffffffffc0203656:	7906                	ld	s2,96(sp)
ffffffffc0203658:	69e6                	ld	s3,88(sp)
ffffffffc020365a:	6a46                	ld	s4,80(sp)
ffffffffc020365c:	6aa6                	ld	s5,72(sp)
ffffffffc020365e:	6b06                	ld	s6,64(sp)
ffffffffc0203660:	7be2                	ld	s7,56(sp)
ffffffffc0203662:	7c42                	ld	s8,48(sp)
ffffffffc0203664:	7ca2                	ld	s9,40(sp)
ffffffffc0203666:	7d02                	ld	s10,32(sp)
ffffffffc0203668:	6de2                	ld	s11,24(sp)
ffffffffc020366a:	853e                	mv	a0,a5
ffffffffc020366c:	6109                	addi	sp,sp,128
ffffffffc020366e:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203670:	100026f3          	csrr	a3,sstatus
ffffffffc0203674:	8a89                	andi	a3,a3,2
ffffffffc0203676:	e6c5                	bnez	a3,ffffffffc020371e <copy_range+0x1c4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203678:	000d3683          	ld	a3,0(s10)
ffffffffc020367c:	4505                	li	a0,1
ffffffffc020367e:	6e94                	ld	a3,24(a3)
ffffffffc0203680:	9682                	jalr	a3
ffffffffc0203682:	8daa                	mv	s11,a0
                if (npage == NULL) {
ffffffffc0203684:	0a0d8a63          	beqz	s11,ffffffffc0203738 <copy_range+0x1de>
                struct Page *page = pte2page(*ptep);
ffffffffc0203688:	000ab683          	ld	a3,0(s5)
    if (!(pte & PTE_V))
ffffffffc020368c:	0016f793          	andi	a5,a3,1
ffffffffc0203690:	10078463          	beqz	a5,ffffffffc0203798 <copy_range+0x23e>
    if (PPN(pa) >= npage)
ffffffffc0203694:	000cb303          	ld	t1,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203698:	068a                	slli	a3,a3,0x2
ffffffffc020369a:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc020369c:	0e66fc63          	bgeu	a3,t1,ffffffffc0203794 <copy_range+0x23a>
    return &pages[PPN(pa) - nbase];
ffffffffc02036a0:	fff807b7          	lui	a5,0xfff80
ffffffffc02036a4:	000c3603          	ld	a2,0(s8)
ffffffffc02036a8:	96be                	add	a3,a3,a5
ffffffffc02036aa:	069a                	slli	a3,a3,0x6
ffffffffc02036ac:	00d607b3          	add	a5,a2,a3
                assert(page != NULL);
ffffffffc02036b0:	c3d5                	beqz	a5,ffffffffc0203754 <copy_range+0x1fa>
    return KADDR(page2pa(page));
ffffffffc02036b2:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc02036b4:	8699                	srai	a3,a3,0x6
ffffffffc02036b6:	000805b7          	lui	a1,0x80
ffffffffc02036ba:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc02036bc:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02036be:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02036c0:	0c67ff63          	bgeu	a5,t1,ffffffffc020379e <copy_range+0x244>
ffffffffc02036c4:	000a7717          	auipc	a4,0xa7
ffffffffc02036c8:	05c70713          	addi	a4,a4,92 # ffffffffc02aa720 <va_pa_offset>
ffffffffc02036cc:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc02036ce:	40cd87b3          	sub	a5,s11,a2
    return KADDR(page2pa(page));
ffffffffc02036d2:	6722                	ld	a4,8(sp)
    return page - pages + nbase;
ffffffffc02036d4:	8799                	srai	a5,a5,0x6
ffffffffc02036d6:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc02036d8:	00e7f633          	and	a2,a5,a4
ffffffffc02036dc:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02036e0:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02036e2:	0a667d63          	bgeu	a2,t1,ffffffffc020379c <copy_range+0x242>
                memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02036e6:	6605                	lui	a2,0x1
ffffffffc02036e8:	953e                	add	a0,a0,a5
ffffffffc02036ea:	1b0020ef          	jal	ra,ffffffffc020589a <memcpy>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02036ee:	01f97693          	andi	a3,s2,31
                int ret = page_insert(to, npage, start, perm);
ffffffffc02036f2:	0046e693          	ori	a3,a3,4
ffffffffc02036f6:	865a                	mv	a2,s6
ffffffffc02036f8:	85ee                	mv	a1,s11
ffffffffc02036fa:	8552                	mv	a0,s4
ffffffffc02036fc:	928ff0ef          	jal	ra,ffffffffc0202824 <page_insert>
                if (ret != 0) {
ffffffffc0203700:	ec0504e3          	beqz	a0,ffffffffc02035c8 <copy_range+0x6e>
ffffffffc0203704:	10002773          	csrr	a4,sstatus
ffffffffc0203708:	8b09                	andi	a4,a4,2
ffffffffc020370a:	e02a                	sd	a0,0(sp)
ffffffffc020370c:	eb05                	bnez	a4,ffffffffc020373c <copy_range+0x1e2>
        pmm_manager->free_pages(base, n);
ffffffffc020370e:	000d3703          	ld	a4,0(s10)
ffffffffc0203712:	4585                	li	a1,1
ffffffffc0203714:	856e                	mv	a0,s11
ffffffffc0203716:	7318                	ld	a4,32(a4)
ffffffffc0203718:	9702                	jalr	a4
    if (flag)
ffffffffc020371a:	6782                	ld	a5,0(sp)
ffffffffc020371c:	bf15                	j	ffffffffc0203650 <copy_range+0xf6>
        intr_disable();
ffffffffc020371e:	a96fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203722:	000d3683          	ld	a3,0(s10)
ffffffffc0203726:	4505                	li	a0,1
ffffffffc0203728:	6e94                	ld	a3,24(a3)
ffffffffc020372a:	9682                	jalr	a3
ffffffffc020372c:	8daa                	mv	s11,a0
        intr_enable();
ffffffffc020372e:	a80fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203732:	bf89                	j	ffffffffc0203684 <copy_range+0x12a>
    return 0;
ffffffffc0203734:	4781                	li	a5,0
ffffffffc0203736:	bf29                	j	ffffffffc0203650 <copy_range+0xf6>
                return -E_NO_MEM;
ffffffffc0203738:	57f1                	li	a5,-4
ffffffffc020373a:	bf19                	j	ffffffffc0203650 <copy_range+0xf6>
        intr_disable();
ffffffffc020373c:	a78fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203740:	000d3703          	ld	a4,0(s10)
ffffffffc0203744:	4585                	li	a1,1
ffffffffc0203746:	856e                	mv	a0,s11
ffffffffc0203748:	7318                	ld	a4,32(a4)
ffffffffc020374a:	9702                	jalr	a4
        intr_enable();
ffffffffc020374c:	a62fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203750:	6782                	ld	a5,0(sp)
ffffffffc0203752:	bdfd                	j	ffffffffc0203650 <copy_range+0xf6>
                assert(page != NULL);
ffffffffc0203754:	00003697          	auipc	a3,0x3
ffffffffc0203758:	72468693          	addi	a3,a3,1828 # ffffffffc0206e78 <default_pmm_manager+0x6c0>
ffffffffc020375c:	00003617          	auipc	a2,0x3
ffffffffc0203760:	cac60613          	addi	a2,a2,-852 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203764:	1a500593          	li	a1,421
ffffffffc0203768:	00003517          	auipc	a0,0x3
ffffffffc020376c:	12050513          	addi	a0,a0,288 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc0203770:	d1ffc0ef          	jal	ra,ffffffffc020048e <__panic>
                assert(page != NULL);
ffffffffc0203774:	00003697          	auipc	a3,0x3
ffffffffc0203778:	70468693          	addi	a3,a3,1796 # ffffffffc0206e78 <default_pmm_manager+0x6c0>
ffffffffc020377c:	00003617          	auipc	a2,0x3
ffffffffc0203780:	c8c60613          	addi	a2,a2,-884 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203784:	19500593          	li	a1,405
ffffffffc0203788:	00003517          	auipc	a0,0x3
ffffffffc020378c:	10050513          	addi	a0,a0,256 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc0203790:	cfffc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203794:	8b1fe0ef          	jal	ra,ffffffffc0202044 <pa2page.part.0>
ffffffffc0203798:	8c9fe0ef          	jal	ra,ffffffffc0202060 <pte2page.part.0>
ffffffffc020379c:	86be                	mv	a3,a5
ffffffffc020379e:	00003617          	auipc	a2,0x3
ffffffffc02037a2:	ba260613          	addi	a2,a2,-1118 # ffffffffc0206340 <commands+0x820>
ffffffffc02037a6:	07100593          	li	a1,113
ffffffffc02037aa:	00003517          	auipc	a0,0x3
ffffffffc02037ae:	b4e50513          	addi	a0,a0,-1202 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc02037b2:	cddfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02037b6:	00003697          	auipc	a3,0x3
ffffffffc02037ba:	11268693          	addi	a3,a3,274 # ffffffffc02068c8 <default_pmm_manager+0x110>
ffffffffc02037be:	00003617          	auipc	a2,0x3
ffffffffc02037c2:	c4a60613          	addi	a2,a2,-950 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02037c6:	17c00593          	li	a1,380
ffffffffc02037ca:	00003517          	auipc	a0,0x3
ffffffffc02037ce:	0be50513          	addi	a0,a0,190 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02037d2:	cbdfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02037d6:	00003697          	auipc	a3,0x3
ffffffffc02037da:	0c268693          	addi	a3,a3,194 # ffffffffc0206898 <default_pmm_manager+0xe0>
ffffffffc02037de:	00003617          	auipc	a2,0x3
ffffffffc02037e2:	c2a60613          	addi	a2,a2,-982 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02037e6:	17b00593          	li	a1,379
ffffffffc02037ea:	00003517          	auipc	a0,0x3
ffffffffc02037ee:	09e50513          	addi	a0,a0,158 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02037f2:	c9dfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02037f6 <pgdir_alloc_page>:
{
ffffffffc02037f6:	7179                	addi	sp,sp,-48
ffffffffc02037f8:	ec26                	sd	s1,24(sp)
ffffffffc02037fa:	e84a                	sd	s2,16(sp)
ffffffffc02037fc:	e052                	sd	s4,0(sp)
ffffffffc02037fe:	f406                	sd	ra,40(sp)
ffffffffc0203800:	f022                	sd	s0,32(sp)
ffffffffc0203802:	e44e                	sd	s3,8(sp)
ffffffffc0203804:	8a2a                	mv	s4,a0
ffffffffc0203806:	84ae                	mv	s1,a1
ffffffffc0203808:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020380a:	100027f3          	csrr	a5,sstatus
ffffffffc020380e:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc0203810:	000a7997          	auipc	s3,0xa7
ffffffffc0203814:	f0898993          	addi	s3,s3,-248 # ffffffffc02aa718 <pmm_manager>
ffffffffc0203818:	ef8d                	bnez	a5,ffffffffc0203852 <pgdir_alloc_page+0x5c>
ffffffffc020381a:	0009b783          	ld	a5,0(s3)
ffffffffc020381e:	4505                	li	a0,1
ffffffffc0203820:	6f9c                	ld	a5,24(a5)
ffffffffc0203822:	9782                	jalr	a5
ffffffffc0203824:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0203826:	cc09                	beqz	s0,ffffffffc0203840 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203828:	86ca                	mv	a3,s2
ffffffffc020382a:	8626                	mv	a2,s1
ffffffffc020382c:	85a2                	mv	a1,s0
ffffffffc020382e:	8552                	mv	a0,s4
ffffffffc0203830:	ff5fe0ef          	jal	ra,ffffffffc0202824 <page_insert>
ffffffffc0203834:	e915                	bnez	a0,ffffffffc0203868 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc0203836:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc0203838:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc020383a:	4785                	li	a5,1
ffffffffc020383c:	04f71e63          	bne	a4,a5,ffffffffc0203898 <pgdir_alloc_page+0xa2>
}
ffffffffc0203840:	70a2                	ld	ra,40(sp)
ffffffffc0203842:	8522                	mv	a0,s0
ffffffffc0203844:	7402                	ld	s0,32(sp)
ffffffffc0203846:	64e2                	ld	s1,24(sp)
ffffffffc0203848:	6942                	ld	s2,16(sp)
ffffffffc020384a:	69a2                	ld	s3,8(sp)
ffffffffc020384c:	6a02                	ld	s4,0(sp)
ffffffffc020384e:	6145                	addi	sp,sp,48
ffffffffc0203850:	8082                	ret
        intr_disable();
ffffffffc0203852:	962fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203856:	0009b783          	ld	a5,0(s3)
ffffffffc020385a:	4505                	li	a0,1
ffffffffc020385c:	6f9c                	ld	a5,24(a5)
ffffffffc020385e:	9782                	jalr	a5
ffffffffc0203860:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203862:	94cfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203866:	b7c1                	j	ffffffffc0203826 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203868:	100027f3          	csrr	a5,sstatus
ffffffffc020386c:	8b89                	andi	a5,a5,2
ffffffffc020386e:	eb89                	bnez	a5,ffffffffc0203880 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc0203870:	0009b783          	ld	a5,0(s3)
ffffffffc0203874:	8522                	mv	a0,s0
ffffffffc0203876:	4585                	li	a1,1
ffffffffc0203878:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020387a:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020387c:	9782                	jalr	a5
    if (flag)
ffffffffc020387e:	b7c9                	j	ffffffffc0203840 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc0203880:	934fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203884:	0009b783          	ld	a5,0(s3)
ffffffffc0203888:	8522                	mv	a0,s0
ffffffffc020388a:	4585                	li	a1,1
ffffffffc020388c:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020388e:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203890:	9782                	jalr	a5
        intr_enable();
ffffffffc0203892:	91cfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203896:	b76d                	j	ffffffffc0203840 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203898:	00003697          	auipc	a3,0x3
ffffffffc020389c:	5f068693          	addi	a3,a3,1520 # ffffffffc0206e88 <default_pmm_manager+0x6d0>
ffffffffc02038a0:	00003617          	auipc	a2,0x3
ffffffffc02038a4:	b6860613          	addi	a2,a2,-1176 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02038a8:	1fd00593          	li	a1,509
ffffffffc02038ac:	00003517          	auipc	a0,0x3
ffffffffc02038b0:	fdc50513          	addi	a0,a0,-36 # ffffffffc0206888 <default_pmm_manager+0xd0>
ffffffffc02038b4:	bdbfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038b8 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02038b8:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02038ba:	00003697          	auipc	a3,0x3
ffffffffc02038be:	5e668693          	addi	a3,a3,1510 # ffffffffc0206ea0 <default_pmm_manager+0x6e8>
ffffffffc02038c2:	00003617          	auipc	a2,0x3
ffffffffc02038c6:	b4660613          	addi	a2,a2,-1210 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02038ca:	07400593          	li	a1,116
ffffffffc02038ce:	00003517          	auipc	a0,0x3
ffffffffc02038d2:	5f250513          	addi	a0,a0,1522 # ffffffffc0206ec0 <default_pmm_manager+0x708>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02038d6:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02038d8:	bb7fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038dc <mm_create>:
{
ffffffffc02038dc:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02038de:	04000513          	li	a0,64
{
ffffffffc02038e2:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02038e4:	dbafe0ef          	jal	ra,ffffffffc0201e9e <kmalloc>
    if (mm != NULL)
ffffffffc02038e8:	cd19                	beqz	a0,ffffffffc0203906 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02038ea:	e508                	sd	a0,8(a0)
ffffffffc02038ec:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02038ee:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02038f2:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02038f6:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02038fa:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02038fe:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc0203902:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203906:	60a2                	ld	ra,8(sp)
ffffffffc0203908:	0141                	addi	sp,sp,16
ffffffffc020390a:	8082                	ret

ffffffffc020390c <find_vma>:
{
ffffffffc020390c:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc020390e:	c505                	beqz	a0,ffffffffc0203936 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0203910:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203912:	c501                	beqz	a0,ffffffffc020391a <find_vma+0xe>
ffffffffc0203914:	651c                	ld	a5,8(a0)
ffffffffc0203916:	02f5f263          	bgeu	a1,a5,ffffffffc020393a <find_vma+0x2e>
    return listelm->next;
ffffffffc020391a:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc020391c:	00f68d63          	beq	a3,a5,ffffffffc0203936 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0203920:	fe87b703          	ld	a4,-24(a5) # fffffffffff7ffe8 <end+0x3fcd58a4>
ffffffffc0203924:	00e5e663          	bltu	a1,a4,ffffffffc0203930 <find_vma+0x24>
ffffffffc0203928:	ff07b703          	ld	a4,-16(a5)
ffffffffc020392c:	00e5ec63          	bltu	a1,a4,ffffffffc0203944 <find_vma+0x38>
ffffffffc0203930:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203932:	fef697e3          	bne	a3,a5,ffffffffc0203920 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203936:	4501                	li	a0,0
}
ffffffffc0203938:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020393a:	691c                	ld	a5,16(a0)
ffffffffc020393c:	fcf5ffe3          	bgeu	a1,a5,ffffffffc020391a <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0203940:	ea88                	sd	a0,16(a3)
ffffffffc0203942:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203944:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203948:	ea88                	sd	a0,16(a3)
ffffffffc020394a:	8082                	ret

ffffffffc020394c <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc020394c:	6590                	ld	a2,8(a1)
ffffffffc020394e:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_exit_out_size+0x74ef0>
{
ffffffffc0203952:	1141                	addi	sp,sp,-16
ffffffffc0203954:	e406                	sd	ra,8(sp)
ffffffffc0203956:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203958:	01066763          	bltu	a2,a6,ffffffffc0203966 <insert_vma_struct+0x1a>
ffffffffc020395c:	a085                	j	ffffffffc02039bc <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020395e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203962:	04e66863          	bltu	a2,a4,ffffffffc02039b2 <insert_vma_struct+0x66>
ffffffffc0203966:	86be                	mv	a3,a5
ffffffffc0203968:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc020396a:	fef51ae3          	bne	a0,a5,ffffffffc020395e <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc020396e:	02a68463          	beq	a3,a0,ffffffffc0203996 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203972:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203976:	fe86b883          	ld	a7,-24(a3)
ffffffffc020397a:	08e8f163          	bgeu	a7,a4,ffffffffc02039fc <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020397e:	04e66f63          	bltu	a2,a4,ffffffffc02039dc <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203982:	00f50a63          	beq	a0,a5,ffffffffc0203996 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203986:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020398a:	05076963          	bltu	a4,a6,ffffffffc02039dc <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020398e:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203992:	02c77363          	bgeu	a4,a2,ffffffffc02039b8 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203996:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203998:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020399a:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020399e:	e390                	sd	a2,0(a5)
ffffffffc02039a0:	e690                	sd	a2,8(a3)
}
ffffffffc02039a2:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02039a4:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02039a6:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc02039a8:	0017079b          	addiw	a5,a4,1
ffffffffc02039ac:	d11c                	sw	a5,32(a0)
}
ffffffffc02039ae:	0141                	addi	sp,sp,16
ffffffffc02039b0:	8082                	ret
    if (le_prev != list)
ffffffffc02039b2:	fca690e3          	bne	a3,a0,ffffffffc0203972 <insert_vma_struct+0x26>
ffffffffc02039b6:	bfd1                	j	ffffffffc020398a <insert_vma_struct+0x3e>
ffffffffc02039b8:	f01ff0ef          	jal	ra,ffffffffc02038b8 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02039bc:	00003697          	auipc	a3,0x3
ffffffffc02039c0:	51468693          	addi	a3,a3,1300 # ffffffffc0206ed0 <default_pmm_manager+0x718>
ffffffffc02039c4:	00003617          	auipc	a2,0x3
ffffffffc02039c8:	a4460613          	addi	a2,a2,-1468 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02039cc:	07a00593          	li	a1,122
ffffffffc02039d0:	00003517          	auipc	a0,0x3
ffffffffc02039d4:	4f050513          	addi	a0,a0,1264 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc02039d8:	ab7fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02039dc:	00003697          	auipc	a3,0x3
ffffffffc02039e0:	53468693          	addi	a3,a3,1332 # ffffffffc0206f10 <default_pmm_manager+0x758>
ffffffffc02039e4:	00003617          	auipc	a2,0x3
ffffffffc02039e8:	a2460613          	addi	a2,a2,-1500 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02039ec:	07300593          	li	a1,115
ffffffffc02039f0:	00003517          	auipc	a0,0x3
ffffffffc02039f4:	4d050513          	addi	a0,a0,1232 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc02039f8:	a97fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02039fc:	00003697          	auipc	a3,0x3
ffffffffc0203a00:	4f468693          	addi	a3,a3,1268 # ffffffffc0206ef0 <default_pmm_manager+0x738>
ffffffffc0203a04:	00003617          	auipc	a2,0x3
ffffffffc0203a08:	a0460613          	addi	a2,a2,-1532 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203a0c:	07200593          	li	a1,114
ffffffffc0203a10:	00003517          	auipc	a0,0x3
ffffffffc0203a14:	4b050513          	addi	a0,a0,1200 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203a18:	a77fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a1c <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0203a1c:	591c                	lw	a5,48(a0)
{
ffffffffc0203a1e:	1141                	addi	sp,sp,-16
ffffffffc0203a20:	e406                	sd	ra,8(sp)
ffffffffc0203a22:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203a24:	e78d                	bnez	a5,ffffffffc0203a4e <mm_destroy+0x32>
ffffffffc0203a26:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203a28:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203a2a:	00a40c63          	beq	s0,a0,ffffffffc0203a42 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203a2e:	6118                	ld	a4,0(a0)
ffffffffc0203a30:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203a32:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203a34:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203a36:	e398                	sd	a4,0(a5)
ffffffffc0203a38:	d16fe0ef          	jal	ra,ffffffffc0201f4e <kfree>
    return listelm->next;
ffffffffc0203a3c:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203a3e:	fea418e3          	bne	s0,a0,ffffffffc0203a2e <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203a42:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203a44:	6402                	ld	s0,0(sp)
ffffffffc0203a46:	60a2                	ld	ra,8(sp)
ffffffffc0203a48:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203a4a:	d04fe06f          	j	ffffffffc0201f4e <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203a4e:	00003697          	auipc	a3,0x3
ffffffffc0203a52:	4e268693          	addi	a3,a3,1250 # ffffffffc0206f30 <default_pmm_manager+0x778>
ffffffffc0203a56:	00003617          	auipc	a2,0x3
ffffffffc0203a5a:	9b260613          	addi	a2,a2,-1614 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203a5e:	09e00593          	li	a1,158
ffffffffc0203a62:	00003517          	auipc	a0,0x3
ffffffffc0203a66:	45e50513          	addi	a0,a0,1118 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203a6a:	a25fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a6e <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc0203a6e:	7139                	addi	sp,sp,-64
ffffffffc0203a70:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203a72:	6405                	lui	s0,0x1
ffffffffc0203a74:	147d                	addi	s0,s0,-1
ffffffffc0203a76:	77fd                	lui	a5,0xfffff
ffffffffc0203a78:	9622                	add	a2,a2,s0
ffffffffc0203a7a:	962e                	add	a2,a2,a1
{
ffffffffc0203a7c:	f426                	sd	s1,40(sp)
ffffffffc0203a7e:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203a80:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203a84:	f04a                	sd	s2,32(sp)
ffffffffc0203a86:	ec4e                	sd	s3,24(sp)
ffffffffc0203a88:	e852                	sd	s4,16(sp)
ffffffffc0203a8a:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203a8c:	002005b7          	lui	a1,0x200
ffffffffc0203a90:	00f67433          	and	s0,a2,a5
ffffffffc0203a94:	06b4e363          	bltu	s1,a1,ffffffffc0203afa <mm_map+0x8c>
ffffffffc0203a98:	0684f163          	bgeu	s1,s0,ffffffffc0203afa <mm_map+0x8c>
ffffffffc0203a9c:	4785                	li	a5,1
ffffffffc0203a9e:	07fe                	slli	a5,a5,0x1f
ffffffffc0203aa0:	0487ed63          	bltu	a5,s0,ffffffffc0203afa <mm_map+0x8c>
ffffffffc0203aa4:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203aa6:	cd21                	beqz	a0,ffffffffc0203afe <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203aa8:	85a6                	mv	a1,s1
ffffffffc0203aaa:	8ab6                	mv	s5,a3
ffffffffc0203aac:	8a3a                	mv	s4,a4
ffffffffc0203aae:	e5fff0ef          	jal	ra,ffffffffc020390c <find_vma>
ffffffffc0203ab2:	c501                	beqz	a0,ffffffffc0203aba <mm_map+0x4c>
ffffffffc0203ab4:	651c                	ld	a5,8(a0)
ffffffffc0203ab6:	0487e263          	bltu	a5,s0,ffffffffc0203afa <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203aba:	03000513          	li	a0,48
ffffffffc0203abe:	be0fe0ef          	jal	ra,ffffffffc0201e9e <kmalloc>
ffffffffc0203ac2:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203ac4:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203ac6:	02090163          	beqz	s2,ffffffffc0203ae8 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203aca:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0203acc:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0203ad0:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0203ad4:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0203ad8:	85ca                	mv	a1,s2
ffffffffc0203ada:	e73ff0ef          	jal	ra,ffffffffc020394c <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0203ade:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc0203ae0:	000a0463          	beqz	s4,ffffffffc0203ae8 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0203ae4:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc0203ae8:	70e2                	ld	ra,56(sp)
ffffffffc0203aea:	7442                	ld	s0,48(sp)
ffffffffc0203aec:	74a2                	ld	s1,40(sp)
ffffffffc0203aee:	7902                	ld	s2,32(sp)
ffffffffc0203af0:	69e2                	ld	s3,24(sp)
ffffffffc0203af2:	6a42                	ld	s4,16(sp)
ffffffffc0203af4:	6aa2                	ld	s5,8(sp)
ffffffffc0203af6:	6121                	addi	sp,sp,64
ffffffffc0203af8:	8082                	ret
        return -E_INVAL;
ffffffffc0203afa:	5575                	li	a0,-3
ffffffffc0203afc:	b7f5                	j	ffffffffc0203ae8 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc0203afe:	00003697          	auipc	a3,0x3
ffffffffc0203b02:	44a68693          	addi	a3,a3,1098 # ffffffffc0206f48 <default_pmm_manager+0x790>
ffffffffc0203b06:	00003617          	auipc	a2,0x3
ffffffffc0203b0a:	90260613          	addi	a2,a2,-1790 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203b0e:	0b300593          	li	a1,179
ffffffffc0203b12:	00003517          	auipc	a0,0x3
ffffffffc0203b16:	3ae50513          	addi	a0,a0,942 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203b1a:	975fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203b1e <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203b1e:	7139                	addi	sp,sp,-64
ffffffffc0203b20:	fc06                	sd	ra,56(sp)
ffffffffc0203b22:	f822                	sd	s0,48(sp)
ffffffffc0203b24:	f426                	sd	s1,40(sp)
ffffffffc0203b26:	f04a                	sd	s2,32(sp)
ffffffffc0203b28:	ec4e                	sd	s3,24(sp)
ffffffffc0203b2a:	e852                	sd	s4,16(sp)
ffffffffc0203b2c:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203b2e:	c52d                	beqz	a0,ffffffffc0203b98 <dup_mmap+0x7a>
ffffffffc0203b30:	892a                	mv	s2,a0
ffffffffc0203b32:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203b34:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203b36:	e595                	bnez	a1,ffffffffc0203b62 <dup_mmap+0x44>
ffffffffc0203b38:	a085                	j	ffffffffc0203b98 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203b3a:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203b3c:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ee8>
        vma->vm_end = vm_end;
ffffffffc0203b40:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203b44:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203b48:	e05ff0ef          	jal	ra,ffffffffc020394c <insert_vma_struct>

        bool share = 1; // 使用COW机制
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203b4c:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc0203b50:	fe843603          	ld	a2,-24(s0)
ffffffffc0203b54:	6c8c                	ld	a1,24(s1)
ffffffffc0203b56:	01893503          	ld	a0,24(s2)
ffffffffc0203b5a:	4705                	li	a4,1
ffffffffc0203b5c:	9ffff0ef          	jal	ra,ffffffffc020355a <copy_range>
ffffffffc0203b60:	e105                	bnez	a0,ffffffffc0203b80 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203b62:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203b64:	02848863          	beq	s1,s0,ffffffffc0203b94 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b68:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203b6c:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203b70:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203b74:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b78:	b26fe0ef          	jal	ra,ffffffffc0201e9e <kmalloc>
ffffffffc0203b7c:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203b7e:	fd55                	bnez	a0,ffffffffc0203b3a <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203b80:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203b82:	70e2                	ld	ra,56(sp)
ffffffffc0203b84:	7442                	ld	s0,48(sp)
ffffffffc0203b86:	74a2                	ld	s1,40(sp)
ffffffffc0203b88:	7902                	ld	s2,32(sp)
ffffffffc0203b8a:	69e2                	ld	s3,24(sp)
ffffffffc0203b8c:	6a42                	ld	s4,16(sp)
ffffffffc0203b8e:	6aa2                	ld	s5,8(sp)
ffffffffc0203b90:	6121                	addi	sp,sp,64
ffffffffc0203b92:	8082                	ret
    return 0;
ffffffffc0203b94:	4501                	li	a0,0
ffffffffc0203b96:	b7f5                	j	ffffffffc0203b82 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203b98:	00003697          	auipc	a3,0x3
ffffffffc0203b9c:	3c068693          	addi	a3,a3,960 # ffffffffc0206f58 <default_pmm_manager+0x7a0>
ffffffffc0203ba0:	00003617          	auipc	a2,0x3
ffffffffc0203ba4:	86860613          	addi	a2,a2,-1944 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203ba8:	0cf00593          	li	a1,207
ffffffffc0203bac:	00003517          	auipc	a0,0x3
ffffffffc0203bb0:	31450513          	addi	a0,a0,788 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203bb4:	8dbfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203bb8 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203bb8:	1101                	addi	sp,sp,-32
ffffffffc0203bba:	ec06                	sd	ra,24(sp)
ffffffffc0203bbc:	e822                	sd	s0,16(sp)
ffffffffc0203bbe:	e426                	sd	s1,8(sp)
ffffffffc0203bc0:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203bc2:	c531                	beqz	a0,ffffffffc0203c0e <exit_mmap+0x56>
ffffffffc0203bc4:	591c                	lw	a5,48(a0)
ffffffffc0203bc6:	84aa                	mv	s1,a0
ffffffffc0203bc8:	e3b9                	bnez	a5,ffffffffc0203c0e <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203bca:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203bcc:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203bd0:	02850663          	beq	a0,s0,ffffffffc0203bfc <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203bd4:	ff043603          	ld	a2,-16(s0)
ffffffffc0203bd8:	fe843583          	ld	a1,-24(s0)
ffffffffc0203bdc:	854a                	mv	a0,s2
ffffffffc0203bde:	fd2fe0ef          	jal	ra,ffffffffc02023b0 <unmap_range>
ffffffffc0203be2:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203be4:	fe8498e3          	bne	s1,s0,ffffffffc0203bd4 <exit_mmap+0x1c>
ffffffffc0203be8:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203bea:	00848c63          	beq	s1,s0,ffffffffc0203c02 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203bee:	ff043603          	ld	a2,-16(s0)
ffffffffc0203bf2:	fe843583          	ld	a1,-24(s0)
ffffffffc0203bf6:	854a                	mv	a0,s2
ffffffffc0203bf8:	8fffe0ef          	jal	ra,ffffffffc02024f6 <exit_range>
ffffffffc0203bfc:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203bfe:	fe8498e3          	bne	s1,s0,ffffffffc0203bee <exit_mmap+0x36>
    }
}
ffffffffc0203c02:	60e2                	ld	ra,24(sp)
ffffffffc0203c04:	6442                	ld	s0,16(sp)
ffffffffc0203c06:	64a2                	ld	s1,8(sp)
ffffffffc0203c08:	6902                	ld	s2,0(sp)
ffffffffc0203c0a:	6105                	addi	sp,sp,32
ffffffffc0203c0c:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203c0e:	00003697          	auipc	a3,0x3
ffffffffc0203c12:	36a68693          	addi	a3,a3,874 # ffffffffc0206f78 <default_pmm_manager+0x7c0>
ffffffffc0203c16:	00002617          	auipc	a2,0x2
ffffffffc0203c1a:	7f260613          	addi	a2,a2,2034 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203c1e:	0e800593          	li	a1,232
ffffffffc0203c22:	00003517          	auipc	a0,0x3
ffffffffc0203c26:	29e50513          	addi	a0,a0,670 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203c2a:	865fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203c2e <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203c2e:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203c30:	04000513          	li	a0,64
{
ffffffffc0203c34:	fc06                	sd	ra,56(sp)
ffffffffc0203c36:	f822                	sd	s0,48(sp)
ffffffffc0203c38:	f426                	sd	s1,40(sp)
ffffffffc0203c3a:	f04a                	sd	s2,32(sp)
ffffffffc0203c3c:	ec4e                	sd	s3,24(sp)
ffffffffc0203c3e:	e852                	sd	s4,16(sp)
ffffffffc0203c40:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203c42:	a5cfe0ef          	jal	ra,ffffffffc0201e9e <kmalloc>
    if (mm != NULL)
ffffffffc0203c46:	2e050663          	beqz	a0,ffffffffc0203f32 <vmm_init+0x304>
ffffffffc0203c4a:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203c4c:	e508                	sd	a0,8(a0)
ffffffffc0203c4e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203c50:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203c54:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203c58:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203c5c:	02053423          	sd	zero,40(a0)
ffffffffc0203c60:	02052823          	sw	zero,48(a0)
ffffffffc0203c64:	02053c23          	sd	zero,56(a0)
ffffffffc0203c68:	03200413          	li	s0,50
ffffffffc0203c6c:	a811                	j	ffffffffc0203c80 <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203c6e:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203c70:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203c72:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203c76:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203c78:	8526                	mv	a0,s1
ffffffffc0203c7a:	cd3ff0ef          	jal	ra,ffffffffc020394c <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203c7e:	c80d                	beqz	s0,ffffffffc0203cb0 <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203c80:	03000513          	li	a0,48
ffffffffc0203c84:	a1afe0ef          	jal	ra,ffffffffc0201e9e <kmalloc>
ffffffffc0203c88:	85aa                	mv	a1,a0
ffffffffc0203c8a:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203c8e:	f165                	bnez	a0,ffffffffc0203c6e <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203c90:	00003697          	auipc	a3,0x3
ffffffffc0203c94:	48068693          	addi	a3,a3,1152 # ffffffffc0207110 <default_pmm_manager+0x958>
ffffffffc0203c98:	00002617          	auipc	a2,0x2
ffffffffc0203c9c:	77060613          	addi	a2,a2,1904 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203ca0:	12c00593          	li	a1,300
ffffffffc0203ca4:	00003517          	auipc	a0,0x3
ffffffffc0203ca8:	21c50513          	addi	a0,a0,540 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203cac:	fe2fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203cb0:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203cb4:	1f900913          	li	s2,505
ffffffffc0203cb8:	a819                	j	ffffffffc0203cce <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203cba:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203cbc:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203cbe:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203cc2:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203cc4:	8526                	mv	a0,s1
ffffffffc0203cc6:	c87ff0ef          	jal	ra,ffffffffc020394c <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203cca:	03240a63          	beq	s0,s2,ffffffffc0203cfe <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203cce:	03000513          	li	a0,48
ffffffffc0203cd2:	9ccfe0ef          	jal	ra,ffffffffc0201e9e <kmalloc>
ffffffffc0203cd6:	85aa                	mv	a1,a0
ffffffffc0203cd8:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203cdc:	fd79                	bnez	a0,ffffffffc0203cba <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203cde:	00003697          	auipc	a3,0x3
ffffffffc0203ce2:	43268693          	addi	a3,a3,1074 # ffffffffc0207110 <default_pmm_manager+0x958>
ffffffffc0203ce6:	00002617          	auipc	a2,0x2
ffffffffc0203cea:	72260613          	addi	a2,a2,1826 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203cee:	13300593          	li	a1,307
ffffffffc0203cf2:	00003517          	auipc	a0,0x3
ffffffffc0203cf6:	1ce50513          	addi	a0,a0,462 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203cfa:	f94fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203cfe:	649c                	ld	a5,8(s1)
ffffffffc0203d00:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203d02:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203d06:	16f48663          	beq	s1,a5,ffffffffc0203e72 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203d0a:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd548a4>
ffffffffc0203d0e:	ffe70693          	addi	a3,a4,-2
ffffffffc0203d12:	10d61063          	bne	a2,a3,ffffffffc0203e12 <vmm_init+0x1e4>
ffffffffc0203d16:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203d1a:	0ed71c63          	bne	a4,a3,ffffffffc0203e12 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203d1e:	0715                	addi	a4,a4,5
ffffffffc0203d20:	679c                	ld	a5,8(a5)
ffffffffc0203d22:	feb712e3          	bne	a4,a1,ffffffffc0203d06 <vmm_init+0xd8>
ffffffffc0203d26:	4a1d                	li	s4,7
ffffffffc0203d28:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203d2a:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203d2e:	85a2                	mv	a1,s0
ffffffffc0203d30:	8526                	mv	a0,s1
ffffffffc0203d32:	bdbff0ef          	jal	ra,ffffffffc020390c <find_vma>
ffffffffc0203d36:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203d38:	16050d63          	beqz	a0,ffffffffc0203eb2 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203d3c:	00140593          	addi	a1,s0,1
ffffffffc0203d40:	8526                	mv	a0,s1
ffffffffc0203d42:	bcbff0ef          	jal	ra,ffffffffc020390c <find_vma>
ffffffffc0203d46:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203d48:	14050563          	beqz	a0,ffffffffc0203e92 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203d4c:	85d2                	mv	a1,s4
ffffffffc0203d4e:	8526                	mv	a0,s1
ffffffffc0203d50:	bbdff0ef          	jal	ra,ffffffffc020390c <find_vma>
        assert(vma3 == NULL);
ffffffffc0203d54:	16051f63          	bnez	a0,ffffffffc0203ed2 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203d58:	00340593          	addi	a1,s0,3
ffffffffc0203d5c:	8526                	mv	a0,s1
ffffffffc0203d5e:	bafff0ef          	jal	ra,ffffffffc020390c <find_vma>
        assert(vma4 == NULL);
ffffffffc0203d62:	1a051863          	bnez	a0,ffffffffc0203f12 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203d66:	00440593          	addi	a1,s0,4
ffffffffc0203d6a:	8526                	mv	a0,s1
ffffffffc0203d6c:	ba1ff0ef          	jal	ra,ffffffffc020390c <find_vma>
        assert(vma5 == NULL);
ffffffffc0203d70:	18051163          	bnez	a0,ffffffffc0203ef2 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203d74:	00893783          	ld	a5,8(s2)
ffffffffc0203d78:	0a879d63          	bne	a5,s0,ffffffffc0203e32 <vmm_init+0x204>
ffffffffc0203d7c:	01093783          	ld	a5,16(s2)
ffffffffc0203d80:	0b479963          	bne	a5,s4,ffffffffc0203e32 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203d84:	0089b783          	ld	a5,8(s3)
ffffffffc0203d88:	0c879563          	bne	a5,s0,ffffffffc0203e52 <vmm_init+0x224>
ffffffffc0203d8c:	0109b783          	ld	a5,16(s3)
ffffffffc0203d90:	0d479163          	bne	a5,s4,ffffffffc0203e52 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203d94:	0415                	addi	s0,s0,5
ffffffffc0203d96:	0a15                	addi	s4,s4,5
ffffffffc0203d98:	f9541be3          	bne	s0,s5,ffffffffc0203d2e <vmm_init+0x100>
ffffffffc0203d9c:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203d9e:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203da0:	85a2                	mv	a1,s0
ffffffffc0203da2:	8526                	mv	a0,s1
ffffffffc0203da4:	b69ff0ef          	jal	ra,ffffffffc020390c <find_vma>
ffffffffc0203da8:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203dac:	c90d                	beqz	a0,ffffffffc0203dde <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203dae:	6914                	ld	a3,16(a0)
ffffffffc0203db0:	6510                	ld	a2,8(a0)
ffffffffc0203db2:	00003517          	auipc	a0,0x3
ffffffffc0203db6:	2e650513          	addi	a0,a0,742 # ffffffffc0207098 <default_pmm_manager+0x8e0>
ffffffffc0203dba:	bdafc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203dbe:	00003697          	auipc	a3,0x3
ffffffffc0203dc2:	30268693          	addi	a3,a3,770 # ffffffffc02070c0 <default_pmm_manager+0x908>
ffffffffc0203dc6:	00002617          	auipc	a2,0x2
ffffffffc0203dca:	64260613          	addi	a2,a2,1602 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203dce:	15900593          	li	a1,345
ffffffffc0203dd2:	00003517          	auipc	a0,0x3
ffffffffc0203dd6:	0ee50513          	addi	a0,a0,238 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203dda:	eb4fc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203dde:	147d                	addi	s0,s0,-1
ffffffffc0203de0:	fd2410e3          	bne	s0,s2,ffffffffc0203da0 <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203de4:	8526                	mv	a0,s1
ffffffffc0203de6:	c37ff0ef          	jal	ra,ffffffffc0203a1c <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203dea:	00003517          	auipc	a0,0x3
ffffffffc0203dee:	2ee50513          	addi	a0,a0,750 # ffffffffc02070d8 <default_pmm_manager+0x920>
ffffffffc0203df2:	ba2fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203df6:	7442                	ld	s0,48(sp)
ffffffffc0203df8:	70e2                	ld	ra,56(sp)
ffffffffc0203dfa:	74a2                	ld	s1,40(sp)
ffffffffc0203dfc:	7902                	ld	s2,32(sp)
ffffffffc0203dfe:	69e2                	ld	s3,24(sp)
ffffffffc0203e00:	6a42                	ld	s4,16(sp)
ffffffffc0203e02:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203e04:	00003517          	auipc	a0,0x3
ffffffffc0203e08:	2f450513          	addi	a0,a0,756 # ffffffffc02070f8 <default_pmm_manager+0x940>
}
ffffffffc0203e0c:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203e0e:	b86fc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203e12:	00003697          	auipc	a3,0x3
ffffffffc0203e16:	19e68693          	addi	a3,a3,414 # ffffffffc0206fb0 <default_pmm_manager+0x7f8>
ffffffffc0203e1a:	00002617          	auipc	a2,0x2
ffffffffc0203e1e:	5ee60613          	addi	a2,a2,1518 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203e22:	13d00593          	li	a1,317
ffffffffc0203e26:	00003517          	auipc	a0,0x3
ffffffffc0203e2a:	09a50513          	addi	a0,a0,154 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203e2e:	e60fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203e32:	00003697          	auipc	a3,0x3
ffffffffc0203e36:	20668693          	addi	a3,a3,518 # ffffffffc0207038 <default_pmm_manager+0x880>
ffffffffc0203e3a:	00002617          	auipc	a2,0x2
ffffffffc0203e3e:	5ce60613          	addi	a2,a2,1486 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203e42:	14e00593          	li	a1,334
ffffffffc0203e46:	00003517          	auipc	a0,0x3
ffffffffc0203e4a:	07a50513          	addi	a0,a0,122 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203e4e:	e40fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203e52:	00003697          	auipc	a3,0x3
ffffffffc0203e56:	21668693          	addi	a3,a3,534 # ffffffffc0207068 <default_pmm_manager+0x8b0>
ffffffffc0203e5a:	00002617          	auipc	a2,0x2
ffffffffc0203e5e:	5ae60613          	addi	a2,a2,1454 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203e62:	14f00593          	li	a1,335
ffffffffc0203e66:	00003517          	auipc	a0,0x3
ffffffffc0203e6a:	05a50513          	addi	a0,a0,90 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203e6e:	e20fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203e72:	00003697          	auipc	a3,0x3
ffffffffc0203e76:	12668693          	addi	a3,a3,294 # ffffffffc0206f98 <default_pmm_manager+0x7e0>
ffffffffc0203e7a:	00002617          	auipc	a2,0x2
ffffffffc0203e7e:	58e60613          	addi	a2,a2,1422 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203e82:	13b00593          	li	a1,315
ffffffffc0203e86:	00003517          	auipc	a0,0x3
ffffffffc0203e8a:	03a50513          	addi	a0,a0,58 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203e8e:	e00fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203e92:	00003697          	auipc	a3,0x3
ffffffffc0203e96:	16668693          	addi	a3,a3,358 # ffffffffc0206ff8 <default_pmm_manager+0x840>
ffffffffc0203e9a:	00002617          	auipc	a2,0x2
ffffffffc0203e9e:	56e60613          	addi	a2,a2,1390 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203ea2:	14600593          	li	a1,326
ffffffffc0203ea6:	00003517          	auipc	a0,0x3
ffffffffc0203eaa:	01a50513          	addi	a0,a0,26 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203eae:	de0fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203eb2:	00003697          	auipc	a3,0x3
ffffffffc0203eb6:	13668693          	addi	a3,a3,310 # ffffffffc0206fe8 <default_pmm_manager+0x830>
ffffffffc0203eba:	00002617          	auipc	a2,0x2
ffffffffc0203ebe:	54e60613          	addi	a2,a2,1358 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203ec2:	14400593          	li	a1,324
ffffffffc0203ec6:	00003517          	auipc	a0,0x3
ffffffffc0203eca:	ffa50513          	addi	a0,a0,-6 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203ece:	dc0fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203ed2:	00003697          	auipc	a3,0x3
ffffffffc0203ed6:	13668693          	addi	a3,a3,310 # ffffffffc0207008 <default_pmm_manager+0x850>
ffffffffc0203eda:	00002617          	auipc	a2,0x2
ffffffffc0203ede:	52e60613          	addi	a2,a2,1326 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203ee2:	14800593          	li	a1,328
ffffffffc0203ee6:	00003517          	auipc	a0,0x3
ffffffffc0203eea:	fda50513          	addi	a0,a0,-38 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203eee:	da0fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203ef2:	00003697          	auipc	a3,0x3
ffffffffc0203ef6:	13668693          	addi	a3,a3,310 # ffffffffc0207028 <default_pmm_manager+0x870>
ffffffffc0203efa:	00002617          	auipc	a2,0x2
ffffffffc0203efe:	50e60613          	addi	a2,a2,1294 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203f02:	14c00593          	li	a1,332
ffffffffc0203f06:	00003517          	auipc	a0,0x3
ffffffffc0203f0a:	fba50513          	addi	a0,a0,-70 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203f0e:	d80fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203f12:	00003697          	auipc	a3,0x3
ffffffffc0203f16:	10668693          	addi	a3,a3,262 # ffffffffc0207018 <default_pmm_manager+0x860>
ffffffffc0203f1a:	00002617          	auipc	a2,0x2
ffffffffc0203f1e:	4ee60613          	addi	a2,a2,1262 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203f22:	14a00593          	li	a1,330
ffffffffc0203f26:	00003517          	auipc	a0,0x3
ffffffffc0203f2a:	f9a50513          	addi	a0,a0,-102 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203f2e:	d60fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203f32:	00003697          	auipc	a3,0x3
ffffffffc0203f36:	01668693          	addi	a3,a3,22 # ffffffffc0206f48 <default_pmm_manager+0x790>
ffffffffc0203f3a:	00002617          	auipc	a2,0x2
ffffffffc0203f3e:	4ce60613          	addi	a2,a2,1230 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0203f42:	12400593          	li	a1,292
ffffffffc0203f46:	00003517          	auipc	a0,0x3
ffffffffc0203f4a:	f7a50513          	addi	a0,a0,-134 # ffffffffc0206ec0 <default_pmm_manager+0x708>
ffffffffc0203f4e:	d40fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203f52 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203f52:	7179                	addi	sp,sp,-48
ffffffffc0203f54:	f022                	sd	s0,32(sp)
ffffffffc0203f56:	f406                	sd	ra,40(sp)
ffffffffc0203f58:	ec26                	sd	s1,24(sp)
ffffffffc0203f5a:	e84a                	sd	s2,16(sp)
ffffffffc0203f5c:	e44e                	sd	s3,8(sp)
ffffffffc0203f5e:	e052                	sd	s4,0(sp)
ffffffffc0203f60:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203f62:	c135                	beqz	a0,ffffffffc0203fc6 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203f64:	002007b7          	lui	a5,0x200
ffffffffc0203f68:	04f5e663          	bltu	a1,a5,ffffffffc0203fb4 <user_mem_check+0x62>
ffffffffc0203f6c:	00c584b3          	add	s1,a1,a2
ffffffffc0203f70:	0495f263          	bgeu	a1,s1,ffffffffc0203fb4 <user_mem_check+0x62>
ffffffffc0203f74:	4785                	li	a5,1
ffffffffc0203f76:	07fe                	slli	a5,a5,0x1f
ffffffffc0203f78:	0297ee63          	bltu	a5,s1,ffffffffc0203fb4 <user_mem_check+0x62>
ffffffffc0203f7c:	892a                	mv	s2,a0
ffffffffc0203f7e:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f80:	6a05                	lui	s4,0x1
ffffffffc0203f82:	a821                	j	ffffffffc0203f9a <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f84:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f88:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203f8a:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f8c:	c685                	beqz	a3,ffffffffc0203fb4 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203f8e:	c399                	beqz	a5,ffffffffc0203f94 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f90:	02e46263          	bltu	s0,a4,ffffffffc0203fb4 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203f94:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203f96:	04947663          	bgeu	s0,s1,ffffffffc0203fe2 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203f9a:	85a2                	mv	a1,s0
ffffffffc0203f9c:	854a                	mv	a0,s2
ffffffffc0203f9e:	96fff0ef          	jal	ra,ffffffffc020390c <find_vma>
ffffffffc0203fa2:	c909                	beqz	a0,ffffffffc0203fb4 <user_mem_check+0x62>
ffffffffc0203fa4:	6518                	ld	a4,8(a0)
ffffffffc0203fa6:	00e46763          	bltu	s0,a4,ffffffffc0203fb4 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203faa:	4d1c                	lw	a5,24(a0)
ffffffffc0203fac:	fc099ce3          	bnez	s3,ffffffffc0203f84 <user_mem_check+0x32>
ffffffffc0203fb0:	8b85                	andi	a5,a5,1
ffffffffc0203fb2:	f3ed                	bnez	a5,ffffffffc0203f94 <user_mem_check+0x42>
            return 0;
ffffffffc0203fb4:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203fb6:	70a2                	ld	ra,40(sp)
ffffffffc0203fb8:	7402                	ld	s0,32(sp)
ffffffffc0203fba:	64e2                	ld	s1,24(sp)
ffffffffc0203fbc:	6942                	ld	s2,16(sp)
ffffffffc0203fbe:	69a2                	ld	s3,8(sp)
ffffffffc0203fc0:	6a02                	ld	s4,0(sp)
ffffffffc0203fc2:	6145                	addi	sp,sp,48
ffffffffc0203fc4:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203fc6:	c02007b7          	lui	a5,0xc0200
ffffffffc0203fca:	4501                	li	a0,0
ffffffffc0203fcc:	fef5e5e3          	bltu	a1,a5,ffffffffc0203fb6 <user_mem_check+0x64>
ffffffffc0203fd0:	962e                	add	a2,a2,a1
ffffffffc0203fd2:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203fb6 <user_mem_check+0x64>
ffffffffc0203fd6:	c8000537          	lui	a0,0xc8000
ffffffffc0203fda:	0505                	addi	a0,a0,1
ffffffffc0203fdc:	00a63533          	sltu	a0,a2,a0
ffffffffc0203fe0:	bfd9                	j	ffffffffc0203fb6 <user_mem_check+0x64>
        return 1;
ffffffffc0203fe2:	4505                	li	a0,1
ffffffffc0203fe4:	bfc9                	j	ffffffffc0203fb6 <user_mem_check+0x64>

ffffffffc0203fe6 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203fe6:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203fe8:	9402                	jalr	s0

	jal do_exit
ffffffffc0203fea:	5d2000ef          	jal	ra,ffffffffc02045bc <do_exit>

ffffffffc0203fee <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203fee:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203ff0:	10800513          	li	a0,264
{
ffffffffc0203ff4:	e022                	sd	s0,0(sp)
ffffffffc0203ff6:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203ff8:	ea7fd0ef          	jal	ra,ffffffffc0201e9e <kmalloc>
ffffffffc0203ffc:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203ffe:	cd21                	beqz	a0,ffffffffc0204056 <alloc_proc+0x68>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
         proc->state = 0;//初始值PROC_UNINIT
ffffffffc0204000:	57fd                	li	a5,-1
ffffffffc0204002:	1782                	slli	a5,a5,0x20
ffffffffc0204004:	e11c                	sd	a5,0(a0)
         proc->runs = 0;
         proc->kstack = 0;
         proc->need_resched = 0; //不用schedule调度其他进程
         proc->parent = NULL;
         proc->mm = NULL;
         memset(&proc->context, 0, sizeof(struct context));
ffffffffc0204006:	07000613          	li	a2,112
ffffffffc020400a:	4581                	li	a1,0
         proc->runs = 0;
ffffffffc020400c:	00052423          	sw	zero,8(a0) # ffffffffc8000008 <end+0x7d558c4>
         proc->kstack = 0;
ffffffffc0204010:	00053823          	sd	zero,16(a0)
         proc->need_resched = 0; //不用schedule调度其他进程
ffffffffc0204014:	00053c23          	sd	zero,24(a0)
         proc->parent = NULL;
ffffffffc0204018:	02053023          	sd	zero,32(a0)
         proc->mm = NULL;
ffffffffc020401c:	02053423          	sd	zero,40(a0)
         memset(&proc->context, 0, sizeof(struct context));
ffffffffc0204020:	03050513          	addi	a0,a0,48
ffffffffc0204024:	065010ef          	jal	ra,ffffffffc0205888 <memset>
         proc->tf = NULL;
         proc->pgdir = boot_pgdir_pa;
ffffffffc0204028:	000a6797          	auipc	a5,0xa6
ffffffffc020402c:	6d07b783          	ld	a5,1744(a5) # ffffffffc02aa6f8 <boot_pgdir_pa>
         proc->tf = NULL;
ffffffffc0204030:	0a043023          	sd	zero,160(s0)
         proc->pgdir = boot_pgdir_pa;
ffffffffc0204034:	f45c                	sd	a5,168(s0)
         //cprintf("boot_pgdir_pa: %lx\n", boot_pgdir_pa);
         proc->flags = 0;
ffffffffc0204036:	0a042823          	sw	zero,176(s0)
         memset(proc->name, 0, sizeof(proc->name));
ffffffffc020403a:	4641                	li	a2,16
ffffffffc020403c:	4581                	li	a1,0
ffffffffc020403e:	0b440513          	addi	a0,s0,180
ffffffffc0204042:	047010ef          	jal	ra,ffffffffc0205888 <memset>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
         proc->wait_state = 0;
ffffffffc0204046:	0e042623          	sw	zero,236(s0)
            proc->cptr = NULL;
ffffffffc020404a:	0e043823          	sd	zero,240(s0)
            proc->yptr = NULL;
ffffffffc020404e:	0e043c23          	sd	zero,248(s0)
            proc->optr = NULL;
ffffffffc0204052:	10043023          	sd	zero,256(s0)
    }
    return proc;
}
ffffffffc0204056:	60a2                	ld	ra,8(sp)
ffffffffc0204058:	8522                	mv	a0,s0
ffffffffc020405a:	6402                	ld	s0,0(sp)
ffffffffc020405c:	0141                	addi	sp,sp,16
ffffffffc020405e:	8082                	ret

ffffffffc0204060 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0204060:	000a6797          	auipc	a5,0xa6
ffffffffc0204064:	6c87b783          	ld	a5,1736(a5) # ffffffffc02aa728 <current>
ffffffffc0204068:	73c8                	ld	a0,160(a5)
ffffffffc020406a:	8a8fd06f          	j	ffffffffc0201112 <forkrets>

ffffffffc020406e <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)// 进入kernel_execve，然后内联汇编，因为SYS_exec映射到sys_exec，然后sys_exec里return的是do_execve
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc020406e:	000a6797          	auipc	a5,0xa6
ffffffffc0204072:	6ba7b783          	ld	a5,1722(a5) # ffffffffc02aa728 <current>
ffffffffc0204076:	43cc                	lw	a1,4(a5)
{
ffffffffc0204078:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc020407a:	00003617          	auipc	a2,0x3
ffffffffc020407e:	0a660613          	addi	a2,a2,166 # ffffffffc0207120 <default_pmm_manager+0x968>
ffffffffc0204082:	00003517          	auipc	a0,0x3
ffffffffc0204086:	0ae50513          	addi	a0,a0,174 # ffffffffc0207130 <default_pmm_manager+0x978>
{
ffffffffc020408a:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc020408c:	908fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0204090:	3fe07797          	auipc	a5,0x3fe07
ffffffffc0204094:	8d878793          	addi	a5,a5,-1832 # a968 <_binary_obj___user_forktest_out_size>
ffffffffc0204098:	e43e                	sd	a5,8(sp)
ffffffffc020409a:	00003517          	auipc	a0,0x3
ffffffffc020409e:	08650513          	addi	a0,a0,134 # ffffffffc0207120 <default_pmm_manager+0x968>
ffffffffc02040a2:	00045797          	auipc	a5,0x45
ffffffffc02040a6:	64e78793          	addi	a5,a5,1614 # ffffffffc02496f0 <_binary_obj___user_forktest_out_start>
ffffffffc02040aa:	f03e                	sd	a5,32(sp)
ffffffffc02040ac:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc02040ae:	e802                	sd	zero,16(sp)
ffffffffc02040b0:	736010ef          	jal	ra,ffffffffc02057e6 <strlen>
ffffffffc02040b4:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc02040b6:	4511                	li	a0,4
ffffffffc02040b8:	55a2                	lw	a1,40(sp)
ffffffffc02040ba:	4662                	lw	a2,24(sp)
ffffffffc02040bc:	5682                	lw	a3,32(sp)
ffffffffc02040be:	4722                	lw	a4,8(sp)
ffffffffc02040c0:	48a9                	li	a7,10
ffffffffc02040c2:	9002                	ebreak
ffffffffc02040c4:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc02040c6:	65c2                	ld	a1,16(sp)
ffffffffc02040c8:	00003517          	auipc	a0,0x3
ffffffffc02040cc:	09050513          	addi	a0,a0,144 # ffffffffc0207158 <default_pmm_manager+0x9a0>
ffffffffc02040d0:	8c4fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc02040d4:	00003617          	auipc	a2,0x3
ffffffffc02040d8:	09460613          	addi	a2,a2,148 # ffffffffc0207168 <default_pmm_manager+0x9b0>
ffffffffc02040dc:	3ad00593          	li	a1,941
ffffffffc02040e0:	00003517          	auipc	a0,0x3
ffffffffc02040e4:	0a850513          	addi	a0,a0,168 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc02040e8:	ba6fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02040ec <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc02040ec:	6d14                	ld	a3,24(a0)
{
ffffffffc02040ee:	1141                	addi	sp,sp,-16
ffffffffc02040f0:	e406                	sd	ra,8(sp)
ffffffffc02040f2:	c02007b7          	lui	a5,0xc0200
ffffffffc02040f6:	02f6ee63          	bltu	a3,a5,ffffffffc0204132 <put_pgdir+0x46>
ffffffffc02040fa:	000a6517          	auipc	a0,0xa6
ffffffffc02040fe:	62653503          	ld	a0,1574(a0) # ffffffffc02aa720 <va_pa_offset>
ffffffffc0204102:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0204104:	82b1                	srli	a3,a3,0xc
ffffffffc0204106:	000a6797          	auipc	a5,0xa6
ffffffffc020410a:	6027b783          	ld	a5,1538(a5) # ffffffffc02aa708 <npage>
ffffffffc020410e:	02f6fe63          	bgeu	a3,a5,ffffffffc020414a <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204112:	00004517          	auipc	a0,0x4
ffffffffc0204116:	90e53503          	ld	a0,-1778(a0) # ffffffffc0207a20 <nbase>
}
ffffffffc020411a:	60a2                	ld	ra,8(sp)
ffffffffc020411c:	8e89                	sub	a3,a3,a0
ffffffffc020411e:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204120:	000a6517          	auipc	a0,0xa6
ffffffffc0204124:	5f053503          	ld	a0,1520(a0) # ffffffffc02aa710 <pages>
ffffffffc0204128:	4585                	li	a1,1
ffffffffc020412a:	9536                	add	a0,a0,a3
}
ffffffffc020412c:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc020412e:	f8dfd06f          	j	ffffffffc02020ba <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204132:	00002617          	auipc	a2,0x2
ffffffffc0204136:	72e60613          	addi	a2,a2,1838 # ffffffffc0206860 <default_pmm_manager+0xa8>
ffffffffc020413a:	07700593          	li	a1,119
ffffffffc020413e:	00002517          	auipc	a0,0x2
ffffffffc0204142:	1ba50513          	addi	a0,a0,442 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc0204146:	b48fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020414a:	00002617          	auipc	a2,0x2
ffffffffc020414e:	1be60613          	addi	a2,a2,446 # ffffffffc0206308 <commands+0x7e8>
ffffffffc0204152:	06900593          	li	a1,105
ffffffffc0204156:	00002517          	auipc	a0,0x2
ffffffffc020415a:	1a250513          	addi	a0,a0,418 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc020415e:	b30fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204162 <proc_run>:
{
ffffffffc0204162:	7179                	addi	sp,sp,-48
ffffffffc0204164:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0204166:	000a6497          	auipc	s1,0xa6
ffffffffc020416a:	5c248493          	addi	s1,s1,1474 # ffffffffc02aa728 <current>
ffffffffc020416e:	6098                	ld	a4,0(s1)
{
ffffffffc0204170:	f406                	sd	ra,40(sp)
ffffffffc0204172:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0204174:	02a70763          	beq	a4,a0,ffffffffc02041a2 <proc_run+0x40>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204178:	100027f3          	csrr	a5,sstatus
ffffffffc020417c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020417e:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204180:	ef85                	bnez	a5,ffffffffc02041b8 <proc_run+0x56>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0204182:	755c                	ld	a5,168(a0)
ffffffffc0204184:	56fd                	li	a3,-1
ffffffffc0204186:	16fe                	slli	a3,a3,0x3f
ffffffffc0204188:	83b1                	srli	a5,a5,0xc
         current = proc;
ffffffffc020418a:	e088                	sd	a0,0(s1)
ffffffffc020418c:	8fd5                	or	a5,a5,a3
ffffffffc020418e:	18079073          	csrw	satp,a5
         switch_to(&prev->context,&current->context);
ffffffffc0204192:	03050593          	addi	a1,a0,48
ffffffffc0204196:	03070513          	addi	a0,a4,48
ffffffffc020419a:	7f3000ef          	jal	ra,ffffffffc020518c <switch_to>
    if (flag)
ffffffffc020419e:	00091763          	bnez	s2,ffffffffc02041ac <proc_run+0x4a>
}
ffffffffc02041a2:	70a2                	ld	ra,40(sp)
ffffffffc02041a4:	7482                	ld	s1,32(sp)
ffffffffc02041a6:	6962                	ld	s2,24(sp)
ffffffffc02041a8:	6145                	addi	sp,sp,48
ffffffffc02041aa:	8082                	ret
ffffffffc02041ac:	70a2                	ld	ra,40(sp)
ffffffffc02041ae:	7482                	ld	s1,32(sp)
ffffffffc02041b0:	6962                	ld	s2,24(sp)
ffffffffc02041b2:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc02041b4:	ffafc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc02041b8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02041ba:	ffafc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
         struct proc_struct *prev = current;
ffffffffc02041be:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc02041c0:	6522                	ld	a0,8(sp)
ffffffffc02041c2:	4905                	li	s2,1
ffffffffc02041c4:	bf7d                	j	ffffffffc0204182 <proc_run+0x20>

ffffffffc02041c6 <do_fork>:
{
ffffffffc02041c6:	7119                	addi	sp,sp,-128
ffffffffc02041c8:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02041ca:	000a6917          	auipc	s2,0xa6
ffffffffc02041ce:	57690913          	addi	s2,s2,1398 # ffffffffc02aa740 <nr_process>
ffffffffc02041d2:	00092703          	lw	a4,0(s2)
{
ffffffffc02041d6:	fc86                	sd	ra,120(sp)
ffffffffc02041d8:	f8a2                	sd	s0,112(sp)
ffffffffc02041da:	f4a6                	sd	s1,104(sp)
ffffffffc02041dc:	ecce                	sd	s3,88(sp)
ffffffffc02041de:	e8d2                	sd	s4,80(sp)
ffffffffc02041e0:	e4d6                	sd	s5,72(sp)
ffffffffc02041e2:	e0da                	sd	s6,64(sp)
ffffffffc02041e4:	fc5e                	sd	s7,56(sp)
ffffffffc02041e6:	f862                	sd	s8,48(sp)
ffffffffc02041e8:	f466                	sd	s9,40(sp)
ffffffffc02041ea:	f06a                	sd	s10,32(sp)
ffffffffc02041ec:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02041ee:	6785                	lui	a5,0x1
ffffffffc02041f0:	2ef75c63          	bge	a4,a5,ffffffffc02044e8 <do_fork+0x322>
ffffffffc02041f4:	8a2a                	mv	s4,a0
ffffffffc02041f6:	89ae                	mv	s3,a1
ffffffffc02041f8:	8432                	mv	s0,a2
    proc = alloc_proc();
ffffffffc02041fa:	df5ff0ef          	jal	ra,ffffffffc0203fee <alloc_proc>
ffffffffc02041fe:	84aa                	mv	s1,a0
    if(proc == NULL)
ffffffffc0204200:	2c050863          	beqz	a0,ffffffffc02044d0 <do_fork+0x30a>
    proc->parent = current;          // 父进程为当前进程
ffffffffc0204204:	000a6c17          	auipc	s8,0xa6
ffffffffc0204208:	524c0c13          	addi	s8,s8,1316 # ffffffffc02aa728 <current>
ffffffffc020420c:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204210:	4509                	li	a0,2
    proc->parent = current;          // 父进程为当前进程
ffffffffc0204212:	f09c                	sd	a5,32(s1)
    current->wait_state = 0; // 确保当前进程的 wait_state 为 0
ffffffffc0204214:	0e07a623          	sw	zero,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8abc>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204218:	e65fd0ef          	jal	ra,ffffffffc020207c <alloc_pages>
    if (page != NULL)
ffffffffc020421c:	2a050763          	beqz	a0,ffffffffc02044ca <do_fork+0x304>
    return page - pages + nbase;
ffffffffc0204220:	000a6a97          	auipc	s5,0xa6
ffffffffc0204224:	4f0a8a93          	addi	s5,s5,1264 # ffffffffc02aa710 <pages>
ffffffffc0204228:	000ab683          	ld	a3,0(s5)
ffffffffc020422c:	00003b17          	auipc	s6,0x3
ffffffffc0204230:	7f4b0b13          	addi	s6,s6,2036 # ffffffffc0207a20 <nbase>
ffffffffc0204234:	000b3783          	ld	a5,0(s6)
ffffffffc0204238:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc020423c:	000a6b97          	auipc	s7,0xa6
ffffffffc0204240:	4ccb8b93          	addi	s7,s7,1228 # ffffffffc02aa708 <npage>
    return page - pages + nbase;
ffffffffc0204244:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204246:	5dfd                	li	s11,-1
ffffffffc0204248:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc020424c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020424e:	00cddd93          	srli	s11,s11,0xc
ffffffffc0204252:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204256:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204258:	2ce67563          	bgeu	a2,a4,ffffffffc0204522 <do_fork+0x35c>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc020425c:	000c3603          	ld	a2,0(s8)
ffffffffc0204260:	000a6c17          	auipc	s8,0xa6
ffffffffc0204264:	4c0c0c13          	addi	s8,s8,1216 # ffffffffc02aa720 <va_pa_offset>
ffffffffc0204268:	000c3703          	ld	a4,0(s8)
ffffffffc020426c:	02863d03          	ld	s10,40(a2)
ffffffffc0204270:	e43e                	sd	a5,8(sp)
ffffffffc0204272:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204274:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc0204276:	020d0863          	beqz	s10,ffffffffc02042a6 <do_fork+0xe0>
    if (clone_flags & CLONE_VM)
ffffffffc020427a:	100a7a13          	andi	s4,s4,256
ffffffffc020427e:	180a0863          	beqz	s4,ffffffffc020440e <do_fork+0x248>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0204282:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204286:	018d3783          	ld	a5,24(s10)
ffffffffc020428a:	c02006b7          	lui	a3,0xc0200
ffffffffc020428e:	2705                	addiw	a4,a4,1
ffffffffc0204290:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc0204294:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204298:	2ad7e163          	bltu	a5,a3,ffffffffc020453a <do_fork+0x374>
ffffffffc020429c:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02042a0:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02042a2:	8f99                	sub	a5,a5,a4
ffffffffc02042a4:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02042a6:	6789                	lui	a5,0x2
ffffffffc02042a8:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc8>
ffffffffc02042ac:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc02042ae:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02042b0:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc02042b2:	87b6                	mv	a5,a3
ffffffffc02042b4:	12040893          	addi	a7,s0,288
ffffffffc02042b8:	00063803          	ld	a6,0(a2)
ffffffffc02042bc:	6608                	ld	a0,8(a2)
ffffffffc02042be:	6a0c                	ld	a1,16(a2)
ffffffffc02042c0:	6e18                	ld	a4,24(a2)
ffffffffc02042c2:	0107b023          	sd	a6,0(a5)
ffffffffc02042c6:	e788                	sd	a0,8(a5)
ffffffffc02042c8:	eb8c                	sd	a1,16(a5)
ffffffffc02042ca:	ef98                	sd	a4,24(a5)
ffffffffc02042cc:	02060613          	addi	a2,a2,32
ffffffffc02042d0:	02078793          	addi	a5,a5,32
ffffffffc02042d4:	ff1612e3          	bne	a2,a7,ffffffffc02042b8 <do_fork+0xf2>
    proc->tf->gpr.a0 = 0;
ffffffffc02042d8:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02042dc:	12098763          	beqz	s3,ffffffffc020440a <do_fork+0x244>
    if (++last_pid >= MAX_PID)
ffffffffc02042e0:	000a2817          	auipc	a6,0xa2
ffffffffc02042e4:	fb880813          	addi	a6,a6,-72 # ffffffffc02a6298 <last_pid.1>
ffffffffc02042e8:	00082783          	lw	a5,0(a6)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02042ec:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02042f0:	00000717          	auipc	a4,0x0
ffffffffc02042f4:	d7070713          	addi	a4,a4,-656 # ffffffffc0204060 <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc02042f8:	0017851b          	addiw	a0,a5,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02042fc:	f898                	sd	a4,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02042fe:	fc94                	sd	a3,56(s1)
    if (++last_pid >= MAX_PID)
ffffffffc0204300:	00a82023          	sw	a0,0(a6)
ffffffffc0204304:	6789                	lui	a5,0x2
ffffffffc0204306:	08f55b63          	bge	a0,a5,ffffffffc020439c <do_fork+0x1d6>
    if (last_pid >= next_safe)
ffffffffc020430a:	000a2317          	auipc	t1,0xa2
ffffffffc020430e:	f9230313          	addi	t1,t1,-110 # ffffffffc02a629c <next_safe.0>
ffffffffc0204312:	00032783          	lw	a5,0(t1)
ffffffffc0204316:	000a6417          	auipc	s0,0xa6
ffffffffc020431a:	3a240413          	addi	s0,s0,930 # ffffffffc02aa6b8 <proc_list>
ffffffffc020431e:	08f55763          	bge	a0,a5,ffffffffc02043ac <do_fork+0x1e6>
    proc->pid = get_pid();           // 分配唯一 PID
ffffffffc0204322:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204324:	45a9                	li	a1,10
ffffffffc0204326:	2501                	sext.w	a0,a0
ffffffffc0204328:	0ba010ef          	jal	ra,ffffffffc02053e2 <hash32>
ffffffffc020432c:	02051793          	slli	a5,a0,0x20
ffffffffc0204330:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204334:	000a2797          	auipc	a5,0xa2
ffffffffc0204338:	38478793          	addi	a5,a5,900 # ffffffffc02a66b8 <hash_list>
ffffffffc020433c:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc020433e:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204340:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204342:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc0204346:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0204348:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc020434a:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020434c:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc020434e:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc0204352:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc0204354:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc0204356:	e21c                	sd	a5,0(a2)
ffffffffc0204358:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc020435a:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc020435c:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc020435e:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204362:	10e4b023          	sd	a4,256(s1)
ffffffffc0204366:	c311                	beqz	a4,ffffffffc020436a <do_fork+0x1a4>
        proc->optr->yptr = proc;
ffffffffc0204368:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc020436a:	00092783          	lw	a5,0(s2)
    wakeup_proc(proc);
ffffffffc020436e:	8526                	mv	a0,s1
    proc->parent->cptr = proc;
ffffffffc0204370:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc0204372:	2785                	addiw	a5,a5,1
ffffffffc0204374:	00f92023          	sw	a5,0(s2)
    wakeup_proc(proc);
ffffffffc0204378:	67f000ef          	jal	ra,ffffffffc02051f6 <wakeup_proc>
    ret = proc->pid;
ffffffffc020437c:	40c8                	lw	a0,4(s1)
}
ffffffffc020437e:	70e6                	ld	ra,120(sp)
ffffffffc0204380:	7446                	ld	s0,112(sp)
ffffffffc0204382:	74a6                	ld	s1,104(sp)
ffffffffc0204384:	7906                	ld	s2,96(sp)
ffffffffc0204386:	69e6                	ld	s3,88(sp)
ffffffffc0204388:	6a46                	ld	s4,80(sp)
ffffffffc020438a:	6aa6                	ld	s5,72(sp)
ffffffffc020438c:	6b06                	ld	s6,64(sp)
ffffffffc020438e:	7be2                	ld	s7,56(sp)
ffffffffc0204390:	7c42                	ld	s8,48(sp)
ffffffffc0204392:	7ca2                	ld	s9,40(sp)
ffffffffc0204394:	7d02                	ld	s10,32(sp)
ffffffffc0204396:	6de2                	ld	s11,24(sp)
ffffffffc0204398:	6109                	addi	sp,sp,128
ffffffffc020439a:	8082                	ret
        last_pid = 1;
ffffffffc020439c:	4785                	li	a5,1
ffffffffc020439e:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc02043a2:	4505                	li	a0,1
ffffffffc02043a4:	000a2317          	auipc	t1,0xa2
ffffffffc02043a8:	ef830313          	addi	t1,t1,-264 # ffffffffc02a629c <next_safe.0>
    return listelm->next;
ffffffffc02043ac:	000a6417          	auipc	s0,0xa6
ffffffffc02043b0:	30c40413          	addi	s0,s0,780 # ffffffffc02aa6b8 <proc_list>
ffffffffc02043b4:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc02043b8:	6789                	lui	a5,0x2
ffffffffc02043ba:	00f32023          	sw	a5,0(t1)
ffffffffc02043be:	86aa                	mv	a3,a0
ffffffffc02043c0:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02043c2:	6e89                	lui	t4,0x2
ffffffffc02043c4:	108e0d63          	beq	t3,s0,ffffffffc02044de <do_fork+0x318>
ffffffffc02043c8:	88ae                	mv	a7,a1
ffffffffc02043ca:	87f2                	mv	a5,t3
ffffffffc02043cc:	6609                	lui	a2,0x2
ffffffffc02043ce:	a811                	j	ffffffffc02043e2 <do_fork+0x21c>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02043d0:	00e6d663          	bge	a3,a4,ffffffffc02043dc <do_fork+0x216>
ffffffffc02043d4:	00c75463          	bge	a4,a2,ffffffffc02043dc <do_fork+0x216>
ffffffffc02043d8:	863a                	mv	a2,a4
ffffffffc02043da:	4885                	li	a7,1
ffffffffc02043dc:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02043de:	00878d63          	beq	a5,s0,ffffffffc02043f8 <do_fork+0x232>
            if (proc->pid == last_pid)
ffffffffc02043e2:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c6c>
ffffffffc02043e6:	fed715e3          	bne	a4,a3,ffffffffc02043d0 <do_fork+0x20a>
                if (++last_pid >= next_safe)
ffffffffc02043ea:	2685                	addiw	a3,a3,1
ffffffffc02043ec:	0ec6d463          	bge	a3,a2,ffffffffc02044d4 <do_fork+0x30e>
ffffffffc02043f0:	679c                	ld	a5,8(a5)
ffffffffc02043f2:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02043f4:	fe8797e3          	bne	a5,s0,ffffffffc02043e2 <do_fork+0x21c>
ffffffffc02043f8:	c581                	beqz	a1,ffffffffc0204400 <do_fork+0x23a>
ffffffffc02043fa:	00d82023          	sw	a3,0(a6)
ffffffffc02043fe:	8536                	mv	a0,a3
ffffffffc0204400:	f20881e3          	beqz	a7,ffffffffc0204322 <do_fork+0x15c>
ffffffffc0204404:	00c32023          	sw	a2,0(t1)
ffffffffc0204408:	bf29                	j	ffffffffc0204322 <do_fork+0x15c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020440a:	89b6                	mv	s3,a3
ffffffffc020440c:	bdd1                	j	ffffffffc02042e0 <do_fork+0x11a>
    if ((mm = mm_create()) == NULL)
ffffffffc020440e:	cceff0ef          	jal	ra,ffffffffc02038dc <mm_create>
ffffffffc0204412:	8caa                	mv	s9,a0
ffffffffc0204414:	c159                	beqz	a0,ffffffffc020449a <do_fork+0x2d4>
    if ((page = alloc_page()) == NULL)
ffffffffc0204416:	4505                	li	a0,1
ffffffffc0204418:	c65fd0ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc020441c:	cd25                	beqz	a0,ffffffffc0204494 <do_fork+0x2ce>
    return page - pages + nbase;
ffffffffc020441e:	000ab683          	ld	a3,0(s5)
ffffffffc0204422:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc0204424:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204428:	40d506b3          	sub	a3,a0,a3
ffffffffc020442c:	8699                	srai	a3,a3,0x6
ffffffffc020442e:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204430:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204434:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204436:	0eedf663          	bgeu	s11,a4,ffffffffc0204522 <do_fork+0x35c>
ffffffffc020443a:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020443e:	6605                	lui	a2,0x1
ffffffffc0204440:	000a6597          	auipc	a1,0xa6
ffffffffc0204444:	2c05b583          	ld	a1,704(a1) # ffffffffc02aa700 <boot_pgdir_va>
ffffffffc0204448:	9a36                	add	s4,s4,a3
ffffffffc020444a:	8552                	mv	a0,s4
ffffffffc020444c:	44e010ef          	jal	ra,ffffffffc020589a <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204450:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc0204454:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204458:	4785                	li	a5,1
ffffffffc020445a:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc020445e:	8b85                	andi	a5,a5,1
ffffffffc0204460:	4a05                	li	s4,1
ffffffffc0204462:	c799                	beqz	a5,ffffffffc0204470 <do_fork+0x2aa>
    {
        schedule();
ffffffffc0204464:	613000ef          	jal	ra,ffffffffc0205276 <schedule>
ffffffffc0204468:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc020446c:	8b85                	andi	a5,a5,1
ffffffffc020446e:	fbfd                	bnez	a5,ffffffffc0204464 <do_fork+0x29e>
        ret = dup_mmap(mm, oldmm);
ffffffffc0204470:	85ea                	mv	a1,s10
ffffffffc0204472:	8566                	mv	a0,s9
ffffffffc0204474:	eaaff0ef          	jal	ra,ffffffffc0203b1e <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204478:	57f9                	li	a5,-2
ffffffffc020447a:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc020447e:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc0204480:	cbad                	beqz	a5,ffffffffc02044f2 <do_fork+0x32c>
good_mm:
ffffffffc0204482:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc0204484:	de050fe3          	beqz	a0,ffffffffc0204282 <do_fork+0xbc>
    exit_mmap(mm);
ffffffffc0204488:	8566                	mv	a0,s9
ffffffffc020448a:	f2eff0ef          	jal	ra,ffffffffc0203bb8 <exit_mmap>
    put_pgdir(mm);
ffffffffc020448e:	8566                	mv	a0,s9
ffffffffc0204490:	c5dff0ef          	jal	ra,ffffffffc02040ec <put_pgdir>
    mm_destroy(mm);
ffffffffc0204494:	8566                	mv	a0,s9
ffffffffc0204496:	d86ff0ef          	jal	ra,ffffffffc0203a1c <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020449a:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc020449c:	c02007b7          	lui	a5,0xc0200
ffffffffc02044a0:	0af6ea63          	bltu	a3,a5,ffffffffc0204554 <do_fork+0x38e>
ffffffffc02044a4:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc02044a8:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc02044ac:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02044b0:	83b1                	srli	a5,a5,0xc
ffffffffc02044b2:	04e7fc63          	bgeu	a5,a4,ffffffffc020450a <do_fork+0x344>
    return &pages[PPN(pa) - nbase];
ffffffffc02044b6:	000b3703          	ld	a4,0(s6)
ffffffffc02044ba:	000ab503          	ld	a0,0(s5)
ffffffffc02044be:	4589                	li	a1,2
ffffffffc02044c0:	8f99                	sub	a5,a5,a4
ffffffffc02044c2:	079a                	slli	a5,a5,0x6
ffffffffc02044c4:	953e                	add	a0,a0,a5
ffffffffc02044c6:	bf5fd0ef          	jal	ra,ffffffffc02020ba <free_pages>
    kfree(proc);
ffffffffc02044ca:	8526                	mv	a0,s1
ffffffffc02044cc:	a83fd0ef          	jal	ra,ffffffffc0201f4e <kfree>
    ret = -E_NO_MEM;
ffffffffc02044d0:	5571                	li	a0,-4
    return ret;
ffffffffc02044d2:	b575                	j	ffffffffc020437e <do_fork+0x1b8>
                    if (last_pid >= MAX_PID)
ffffffffc02044d4:	01d6c363          	blt	a3,t4,ffffffffc02044da <do_fork+0x314>
                        last_pid = 1;
ffffffffc02044d8:	4685                	li	a3,1
                    goto repeat;
ffffffffc02044da:	4585                	li	a1,1
ffffffffc02044dc:	b5e5                	j	ffffffffc02043c4 <do_fork+0x1fe>
ffffffffc02044de:	c599                	beqz	a1,ffffffffc02044ec <do_fork+0x326>
ffffffffc02044e0:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02044e4:	8536                	mv	a0,a3
ffffffffc02044e6:	bd35                	j	ffffffffc0204322 <do_fork+0x15c>
    int ret = -E_NO_FREE_PROC;
ffffffffc02044e8:	556d                	li	a0,-5
ffffffffc02044ea:	bd51                	j	ffffffffc020437e <do_fork+0x1b8>
    return last_pid;
ffffffffc02044ec:	00082503          	lw	a0,0(a6)
ffffffffc02044f0:	bd0d                	j	ffffffffc0204322 <do_fork+0x15c>
    {
        panic("Unlock failed.\n");
ffffffffc02044f2:	00003617          	auipc	a2,0x3
ffffffffc02044f6:	cae60613          	addi	a2,a2,-850 # ffffffffc02071a0 <default_pmm_manager+0x9e8>
ffffffffc02044fa:	03f00593          	li	a1,63
ffffffffc02044fe:	00003517          	auipc	a0,0x3
ffffffffc0204502:	cb250513          	addi	a0,a0,-846 # ffffffffc02071b0 <default_pmm_manager+0x9f8>
ffffffffc0204506:	f89fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020450a:	00002617          	auipc	a2,0x2
ffffffffc020450e:	dfe60613          	addi	a2,a2,-514 # ffffffffc0206308 <commands+0x7e8>
ffffffffc0204512:	06900593          	li	a1,105
ffffffffc0204516:	00002517          	auipc	a0,0x2
ffffffffc020451a:	de250513          	addi	a0,a0,-542 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc020451e:	f71fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0204522:	00002617          	auipc	a2,0x2
ffffffffc0204526:	e1e60613          	addi	a2,a2,-482 # ffffffffc0206340 <commands+0x820>
ffffffffc020452a:	07100593          	li	a1,113
ffffffffc020452e:	00002517          	auipc	a0,0x2
ffffffffc0204532:	dca50513          	addi	a0,a0,-566 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc0204536:	f59fb0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020453a:	86be                	mv	a3,a5
ffffffffc020453c:	00002617          	auipc	a2,0x2
ffffffffc0204540:	32460613          	addi	a2,a2,804 # ffffffffc0206860 <default_pmm_manager+0xa8>
ffffffffc0204544:	18b00593          	li	a1,395
ffffffffc0204548:	00003517          	auipc	a0,0x3
ffffffffc020454c:	c4050513          	addi	a0,a0,-960 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc0204550:	f3ffb0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204554:	00002617          	auipc	a2,0x2
ffffffffc0204558:	30c60613          	addi	a2,a2,780 # ffffffffc0206860 <default_pmm_manager+0xa8>
ffffffffc020455c:	07700593          	li	a1,119
ffffffffc0204560:	00002517          	auipc	a0,0x2
ffffffffc0204564:	d9850513          	addi	a0,a0,-616 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc0204568:	f27fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020456c <kernel_thread>:
{
ffffffffc020456c:	7129                	addi	sp,sp,-320
ffffffffc020456e:	fa22                	sd	s0,304(sp)
ffffffffc0204570:	f626                	sd	s1,296(sp)
ffffffffc0204572:	f24a                	sd	s2,288(sp)
ffffffffc0204574:	84ae                	mv	s1,a1
ffffffffc0204576:	892a                	mv	s2,a0
ffffffffc0204578:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020457a:	4581                	li	a1,0
ffffffffc020457c:	12000613          	li	a2,288
ffffffffc0204580:	850a                	mv	a0,sp
{
ffffffffc0204582:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204584:	304010ef          	jal	ra,ffffffffc0205888 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204588:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020458a:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020458c:	100027f3          	csrr	a5,sstatus
ffffffffc0204590:	edd7f793          	andi	a5,a5,-291
ffffffffc0204594:	1207e793          	ori	a5,a5,288
ffffffffc0204598:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020459a:	860a                	mv	a2,sp
ffffffffc020459c:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02045a0:	00000797          	auipc	a5,0x0
ffffffffc02045a4:	a4678793          	addi	a5,a5,-1466 # ffffffffc0203fe6 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02045a8:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02045aa:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02045ac:	c1bff0ef          	jal	ra,ffffffffc02041c6 <do_fork>
}
ffffffffc02045b0:	70f2                	ld	ra,312(sp)
ffffffffc02045b2:	7452                	ld	s0,304(sp)
ffffffffc02045b4:	74b2                	ld	s1,296(sp)
ffffffffc02045b6:	7912                	ld	s2,288(sp)
ffffffffc02045b8:	6131                	addi	sp,sp,320
ffffffffc02045ba:	8082                	ret

ffffffffc02045bc <do_exit>:
{
ffffffffc02045bc:	7179                	addi	sp,sp,-48
ffffffffc02045be:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02045c0:	000a6417          	auipc	s0,0xa6
ffffffffc02045c4:	16840413          	addi	s0,s0,360 # ffffffffc02aa728 <current>
ffffffffc02045c8:	601c                	ld	a5,0(s0)
{
ffffffffc02045ca:	f406                	sd	ra,40(sp)
ffffffffc02045cc:	ec26                	sd	s1,24(sp)
ffffffffc02045ce:	e84a                	sd	s2,16(sp)
ffffffffc02045d0:	e44e                	sd	s3,8(sp)
ffffffffc02045d2:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc02045d4:	000a6717          	auipc	a4,0xa6
ffffffffc02045d8:	15c73703          	ld	a4,348(a4) # ffffffffc02aa730 <idleproc>
ffffffffc02045dc:	0ce78c63          	beq	a5,a4,ffffffffc02046b4 <do_exit+0xf8>
    if (current == initproc)
ffffffffc02045e0:	000a6497          	auipc	s1,0xa6
ffffffffc02045e4:	15848493          	addi	s1,s1,344 # ffffffffc02aa738 <initproc>
ffffffffc02045e8:	6098                	ld	a4,0(s1)
ffffffffc02045ea:	0ee78b63          	beq	a5,a4,ffffffffc02046e0 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc02045ee:	0287b983          	ld	s3,40(a5)
ffffffffc02045f2:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc02045f4:	02098663          	beqz	s3,ffffffffc0204620 <do_exit+0x64>
ffffffffc02045f8:	000a6797          	auipc	a5,0xa6
ffffffffc02045fc:	1007b783          	ld	a5,256(a5) # ffffffffc02aa6f8 <boot_pgdir_pa>
ffffffffc0204600:	577d                	li	a4,-1
ffffffffc0204602:	177e                	slli	a4,a4,0x3f
ffffffffc0204604:	83b1                	srli	a5,a5,0xc
ffffffffc0204606:	8fd9                	or	a5,a5,a4
ffffffffc0204608:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc020460c:	0309a783          	lw	a5,48(s3)
ffffffffc0204610:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204614:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204618:	cb55                	beqz	a4,ffffffffc02046cc <do_exit+0x110>
        current->mm = NULL;
ffffffffc020461a:	601c                	ld	a5,0(s0)
ffffffffc020461c:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204620:	601c                	ld	a5,0(s0)
ffffffffc0204622:	470d                	li	a4,3
ffffffffc0204624:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0204626:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020462a:	100027f3          	csrr	a5,sstatus
ffffffffc020462e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204630:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204632:	e3f9                	bnez	a5,ffffffffc02046f8 <do_exit+0x13c>
        proc = current->parent;
ffffffffc0204634:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204636:	800007b7          	lui	a5,0x80000
ffffffffc020463a:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc020463c:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc020463e:	0ec52703          	lw	a4,236(a0)
ffffffffc0204642:	0af70f63          	beq	a4,a5,ffffffffc0204700 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc0204646:	6018                	ld	a4,0(s0)
ffffffffc0204648:	7b7c                	ld	a5,240(a4)
ffffffffc020464a:	c3a1                	beqz	a5,ffffffffc020468a <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc020464c:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204650:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204652:	0985                	addi	s3,s3,1
ffffffffc0204654:	a021                	j	ffffffffc020465c <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0204656:	6018                	ld	a4,0(s0)
ffffffffc0204658:	7b7c                	ld	a5,240(a4)
ffffffffc020465a:	cb85                	beqz	a5,ffffffffc020468a <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc020465c:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fe0>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204660:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204662:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204664:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204666:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020466a:	10e7b023          	sd	a4,256(a5)
ffffffffc020466e:	c311                	beqz	a4,ffffffffc0204672 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204670:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204672:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204674:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204676:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204678:	fd271fe3          	bne	a4,s2,ffffffffc0204656 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc020467c:	0ec52783          	lw	a5,236(a0)
ffffffffc0204680:	fd379be3          	bne	a5,s3,ffffffffc0204656 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc0204684:	373000ef          	jal	ra,ffffffffc02051f6 <wakeup_proc>
ffffffffc0204688:	b7f9                	j	ffffffffc0204656 <do_exit+0x9a>
    if (flag)
ffffffffc020468a:	020a1263          	bnez	s4,ffffffffc02046ae <do_exit+0xf2>
    schedule();
ffffffffc020468e:	3e9000ef          	jal	ra,ffffffffc0205276 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204692:	601c                	ld	a5,0(s0)
ffffffffc0204694:	00003617          	auipc	a2,0x3
ffffffffc0204698:	b5460613          	addi	a2,a2,-1196 # ffffffffc02071e8 <default_pmm_manager+0xa30>
ffffffffc020469c:	23300593          	li	a1,563
ffffffffc02046a0:	43d4                	lw	a3,4(a5)
ffffffffc02046a2:	00003517          	auipc	a0,0x3
ffffffffc02046a6:	ae650513          	addi	a0,a0,-1306 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc02046aa:	de5fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc02046ae:	b00fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02046b2:	bff1                	j	ffffffffc020468e <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc02046b4:	00003617          	auipc	a2,0x3
ffffffffc02046b8:	b1460613          	addi	a2,a2,-1260 # ffffffffc02071c8 <default_pmm_manager+0xa10>
ffffffffc02046bc:	1ff00593          	li	a1,511
ffffffffc02046c0:	00003517          	auipc	a0,0x3
ffffffffc02046c4:	ac850513          	addi	a0,a0,-1336 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc02046c8:	dc7fb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc02046cc:	854e                	mv	a0,s3
ffffffffc02046ce:	ceaff0ef          	jal	ra,ffffffffc0203bb8 <exit_mmap>
            put_pgdir(mm);
ffffffffc02046d2:	854e                	mv	a0,s3
ffffffffc02046d4:	a19ff0ef          	jal	ra,ffffffffc02040ec <put_pgdir>
            mm_destroy(mm);
ffffffffc02046d8:	854e                	mv	a0,s3
ffffffffc02046da:	b42ff0ef          	jal	ra,ffffffffc0203a1c <mm_destroy>
ffffffffc02046de:	bf35                	j	ffffffffc020461a <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc02046e0:	00003617          	auipc	a2,0x3
ffffffffc02046e4:	af860613          	addi	a2,a2,-1288 # ffffffffc02071d8 <default_pmm_manager+0xa20>
ffffffffc02046e8:	20300593          	li	a1,515
ffffffffc02046ec:	00003517          	auipc	a0,0x3
ffffffffc02046f0:	a9c50513          	addi	a0,a0,-1380 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc02046f4:	d9bfb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc02046f8:	abcfc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02046fc:	4a05                	li	s4,1
ffffffffc02046fe:	bf1d                	j	ffffffffc0204634 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc0204700:	2f7000ef          	jal	ra,ffffffffc02051f6 <wakeup_proc>
ffffffffc0204704:	b789                	j	ffffffffc0204646 <do_exit+0x8a>

ffffffffc0204706 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc0204706:	715d                	addi	sp,sp,-80
ffffffffc0204708:	f84a                	sd	s2,48(sp)
ffffffffc020470a:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc020470c:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204710:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc0204712:	fc26                	sd	s1,56(sp)
ffffffffc0204714:	f052                	sd	s4,32(sp)
ffffffffc0204716:	ec56                	sd	s5,24(sp)
ffffffffc0204718:	e85a                	sd	s6,16(sp)
ffffffffc020471a:	e45e                	sd	s7,8(sp)
ffffffffc020471c:	e486                	sd	ra,72(sp)
ffffffffc020471e:	e0a2                	sd	s0,64(sp)
ffffffffc0204720:	84aa                	mv	s1,a0
ffffffffc0204722:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0204724:	000a6b97          	auipc	s7,0xa6
ffffffffc0204728:	004b8b93          	addi	s7,s7,4 # ffffffffc02aa728 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc020472c:	00050b1b          	sext.w	s6,a0
ffffffffc0204730:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204734:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0204736:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc0204738:	ccbd                	beqz	s1,ffffffffc02047b6 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc020473a:	0359e863          	bltu	s3,s5,ffffffffc020476a <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020473e:	45a9                	li	a1,10
ffffffffc0204740:	855a                	mv	a0,s6
ffffffffc0204742:	4a1000ef          	jal	ra,ffffffffc02053e2 <hash32>
ffffffffc0204746:	02051793          	slli	a5,a0,0x20
ffffffffc020474a:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020474e:	000a2797          	auipc	a5,0xa2
ffffffffc0204752:	f6a78793          	addi	a5,a5,-150 # ffffffffc02a66b8 <hash_list>
ffffffffc0204756:	953e                	add	a0,a0,a5
ffffffffc0204758:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc020475a:	a029                	j	ffffffffc0204764 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc020475c:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204760:	02978163          	beq	a5,s1,ffffffffc0204782 <do_wait.part.0+0x7c>
ffffffffc0204764:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204766:	fe851be3          	bne	a0,s0,ffffffffc020475c <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc020476a:	5579                	li	a0,-2
}
ffffffffc020476c:	60a6                	ld	ra,72(sp)
ffffffffc020476e:	6406                	ld	s0,64(sp)
ffffffffc0204770:	74e2                	ld	s1,56(sp)
ffffffffc0204772:	7942                	ld	s2,48(sp)
ffffffffc0204774:	79a2                	ld	s3,40(sp)
ffffffffc0204776:	7a02                	ld	s4,32(sp)
ffffffffc0204778:	6ae2                	ld	s5,24(sp)
ffffffffc020477a:	6b42                	ld	s6,16(sp)
ffffffffc020477c:	6ba2                	ld	s7,8(sp)
ffffffffc020477e:	6161                	addi	sp,sp,80
ffffffffc0204780:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204782:	000bb683          	ld	a3,0(s7)
ffffffffc0204786:	f4843783          	ld	a5,-184(s0)
ffffffffc020478a:	fed790e3          	bne	a5,a3,ffffffffc020476a <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020478e:	f2842703          	lw	a4,-216(s0)
ffffffffc0204792:	478d                	li	a5,3
ffffffffc0204794:	0ef70b63          	beq	a4,a5,ffffffffc020488a <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0204798:	4785                	li	a5,1
ffffffffc020479a:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc020479c:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc02047a0:	2d7000ef          	jal	ra,ffffffffc0205276 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc02047a4:	000bb783          	ld	a5,0(s7)
ffffffffc02047a8:	0b07a783          	lw	a5,176(a5)
ffffffffc02047ac:	8b85                	andi	a5,a5,1
ffffffffc02047ae:	d7c9                	beqz	a5,ffffffffc0204738 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc02047b0:	555d                	li	a0,-9
ffffffffc02047b2:	e0bff0ef          	jal	ra,ffffffffc02045bc <do_exit>
        proc = current->cptr;
ffffffffc02047b6:	000bb683          	ld	a3,0(s7)
ffffffffc02047ba:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc02047bc:	d45d                	beqz	s0,ffffffffc020476a <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02047be:	470d                	li	a4,3
ffffffffc02047c0:	a021                	j	ffffffffc02047c8 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc02047c2:	10043403          	ld	s0,256(s0)
ffffffffc02047c6:	d869                	beqz	s0,ffffffffc0204798 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02047c8:	401c                	lw	a5,0(s0)
ffffffffc02047ca:	fee79ce3          	bne	a5,a4,ffffffffc02047c2 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc02047ce:	000a6797          	auipc	a5,0xa6
ffffffffc02047d2:	f627b783          	ld	a5,-158(a5) # ffffffffc02aa730 <idleproc>
ffffffffc02047d6:	0c878963          	beq	a5,s0,ffffffffc02048a8 <do_wait.part.0+0x1a2>
ffffffffc02047da:	000a6797          	auipc	a5,0xa6
ffffffffc02047de:	f5e7b783          	ld	a5,-162(a5) # ffffffffc02aa738 <initproc>
ffffffffc02047e2:	0cf40363          	beq	s0,a5,ffffffffc02048a8 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc02047e6:	000a0663          	beqz	s4,ffffffffc02047f2 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc02047ea:	0e842783          	lw	a5,232(s0)
ffffffffc02047ee:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba8>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02047f2:	100027f3          	csrr	a5,sstatus
ffffffffc02047f6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02047f8:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02047fa:	e7c1                	bnez	a5,ffffffffc0204882 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02047fc:	6c70                	ld	a2,216(s0)
ffffffffc02047fe:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc0204800:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc0204804:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0204806:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204808:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020480a:	6470                	ld	a2,200(s0)
ffffffffc020480c:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc020480e:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204810:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204812:	c319                	beqz	a4,ffffffffc0204818 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0204814:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc0204816:	7c7c                	ld	a5,248(s0)
ffffffffc0204818:	c3b5                	beqz	a5,ffffffffc020487c <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc020481a:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc020481e:	000a6717          	auipc	a4,0xa6
ffffffffc0204822:	f2270713          	addi	a4,a4,-222 # ffffffffc02aa740 <nr_process>
ffffffffc0204826:	431c                	lw	a5,0(a4)
ffffffffc0204828:	37fd                	addiw	a5,a5,-1
ffffffffc020482a:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc020482c:	e5a9                	bnez	a1,ffffffffc0204876 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020482e:	6814                	ld	a3,16(s0)
ffffffffc0204830:	c02007b7          	lui	a5,0xc0200
ffffffffc0204834:	04f6ee63          	bltu	a3,a5,ffffffffc0204890 <do_wait.part.0+0x18a>
ffffffffc0204838:	000a6797          	auipc	a5,0xa6
ffffffffc020483c:	ee87b783          	ld	a5,-280(a5) # ffffffffc02aa720 <va_pa_offset>
ffffffffc0204840:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204842:	82b1                	srli	a3,a3,0xc
ffffffffc0204844:	000a6797          	auipc	a5,0xa6
ffffffffc0204848:	ec47b783          	ld	a5,-316(a5) # ffffffffc02aa708 <npage>
ffffffffc020484c:	06f6fa63          	bgeu	a3,a5,ffffffffc02048c0 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204850:	00003517          	auipc	a0,0x3
ffffffffc0204854:	1d053503          	ld	a0,464(a0) # ffffffffc0207a20 <nbase>
ffffffffc0204858:	8e89                	sub	a3,a3,a0
ffffffffc020485a:	069a                	slli	a3,a3,0x6
ffffffffc020485c:	000a6517          	auipc	a0,0xa6
ffffffffc0204860:	eb453503          	ld	a0,-332(a0) # ffffffffc02aa710 <pages>
ffffffffc0204864:	9536                	add	a0,a0,a3
ffffffffc0204866:	4589                	li	a1,2
ffffffffc0204868:	853fd0ef          	jal	ra,ffffffffc02020ba <free_pages>
    kfree(proc);
ffffffffc020486c:	8522                	mv	a0,s0
ffffffffc020486e:	ee0fd0ef          	jal	ra,ffffffffc0201f4e <kfree>
    return 0;
ffffffffc0204872:	4501                	li	a0,0
ffffffffc0204874:	bde5                	j	ffffffffc020476c <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204876:	938fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020487a:	bf55                	j	ffffffffc020482e <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc020487c:	701c                	ld	a5,32(s0)
ffffffffc020487e:	fbf8                	sd	a4,240(a5)
ffffffffc0204880:	bf79                	j	ffffffffc020481e <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204882:	932fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204886:	4585                	li	a1,1
ffffffffc0204888:	bf95                	j	ffffffffc02047fc <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020488a:	f2840413          	addi	s0,s0,-216
ffffffffc020488e:	b781                	j	ffffffffc02047ce <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204890:	00002617          	auipc	a2,0x2
ffffffffc0204894:	fd060613          	addi	a2,a2,-48 # ffffffffc0206860 <default_pmm_manager+0xa8>
ffffffffc0204898:	07700593          	li	a1,119
ffffffffc020489c:	00002517          	auipc	a0,0x2
ffffffffc02048a0:	a5c50513          	addi	a0,a0,-1444 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc02048a4:	bebfb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc02048a8:	00003617          	auipc	a2,0x3
ffffffffc02048ac:	96060613          	addi	a2,a2,-1696 # ffffffffc0207208 <default_pmm_manager+0xa50>
ffffffffc02048b0:	35500593          	li	a1,853
ffffffffc02048b4:	00003517          	auipc	a0,0x3
ffffffffc02048b8:	8d450513          	addi	a0,a0,-1836 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc02048bc:	bd3fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02048c0:	00002617          	auipc	a2,0x2
ffffffffc02048c4:	a4860613          	addi	a2,a2,-1464 # ffffffffc0206308 <commands+0x7e8>
ffffffffc02048c8:	06900593          	li	a1,105
ffffffffc02048cc:	00002517          	auipc	a0,0x2
ffffffffc02048d0:	a2c50513          	addi	a0,a0,-1492 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc02048d4:	bbbfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02048d8 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02048d8:	1141                	addi	sp,sp,-16
ffffffffc02048da:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02048dc:	81ffd0ef          	jal	ra,ffffffffc02020fa <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02048e0:	dbafd0ef          	jal	ra,ffffffffc0201e9a <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);//创建了新的进程
ffffffffc02048e4:	4601                	li	a2,0
ffffffffc02048e6:	4581                	li	a1,0
ffffffffc02048e8:	fffff517          	auipc	a0,0xfffff
ffffffffc02048ec:	78650513          	addi	a0,a0,1926 # ffffffffc020406e <user_main>
ffffffffc02048f0:	c7dff0ef          	jal	ra,ffffffffc020456c <kernel_thread>
    if (pid <= 0)
ffffffffc02048f4:	00a04563          	bgtz	a0,ffffffffc02048fe <init_main+0x26>
ffffffffc02048f8:	a071                	j	ffffffffc0204984 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0) //只要还能成功回收一个子进程，就继续循环;另一种情况是do_wait中，如果父进程没有僵尸状态的紫禁城，那么触发调度
    {
        schedule();
ffffffffc02048fa:	17d000ef          	jal	ra,ffffffffc0205276 <schedule>
    if (code_store != NULL)
ffffffffc02048fe:	4581                	li	a1,0
ffffffffc0204900:	4501                	li	a0,0
ffffffffc0204902:	e05ff0ef          	jal	ra,ffffffffc0204706 <do_wait.part.0>
    while (do_wait(0, NULL) == 0) //只要还能成功回收一个子进程，就继续循环;另一种情况是do_wait中，如果父进程没有僵尸状态的紫禁城，那么触发调度
ffffffffc0204906:	d975                	beqz	a0,ffffffffc02048fa <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204908:	00003517          	auipc	a0,0x3
ffffffffc020490c:	94050513          	addi	a0,a0,-1728 # ffffffffc0207248 <default_pmm_manager+0xa90>
ffffffffc0204910:	885fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204914:	000a6797          	auipc	a5,0xa6
ffffffffc0204918:	e247b783          	ld	a5,-476(a5) # ffffffffc02aa738 <initproc>
ffffffffc020491c:	7bf8                	ld	a4,240(a5)
ffffffffc020491e:	e339                	bnez	a4,ffffffffc0204964 <init_main+0x8c>
ffffffffc0204920:	7ff8                	ld	a4,248(a5)
ffffffffc0204922:	e329                	bnez	a4,ffffffffc0204964 <init_main+0x8c>
ffffffffc0204924:	1007b703          	ld	a4,256(a5)
ffffffffc0204928:	ef15                	bnez	a4,ffffffffc0204964 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc020492a:	000a6697          	auipc	a3,0xa6
ffffffffc020492e:	e166a683          	lw	a3,-490(a3) # ffffffffc02aa740 <nr_process>
ffffffffc0204932:	4709                	li	a4,2
ffffffffc0204934:	0ae69463          	bne	a3,a4,ffffffffc02049dc <init_main+0x104>
    return listelm->next;
ffffffffc0204938:	000a6697          	auipc	a3,0xa6
ffffffffc020493c:	d8068693          	addi	a3,a3,-640 # ffffffffc02aa6b8 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204940:	6698                	ld	a4,8(a3)
ffffffffc0204942:	0c878793          	addi	a5,a5,200
ffffffffc0204946:	06f71b63          	bne	a4,a5,ffffffffc02049bc <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020494a:	629c                	ld	a5,0(a3)
ffffffffc020494c:	04f71863          	bne	a4,a5,ffffffffc020499c <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204950:	00003517          	auipc	a0,0x3
ffffffffc0204954:	9e050513          	addi	a0,a0,-1568 # ffffffffc0207330 <default_pmm_manager+0xb78>
ffffffffc0204958:	83dfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc020495c:	60a2                	ld	ra,8(sp)
ffffffffc020495e:	4501                	li	a0,0
ffffffffc0204960:	0141                	addi	sp,sp,16
ffffffffc0204962:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204964:	00003697          	auipc	a3,0x3
ffffffffc0204968:	90c68693          	addi	a3,a3,-1780 # ffffffffc0207270 <default_pmm_manager+0xab8>
ffffffffc020496c:	00002617          	auipc	a2,0x2
ffffffffc0204970:	a9c60613          	addi	a2,a2,-1380 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0204974:	3c300593          	li	a1,963
ffffffffc0204978:	00003517          	auipc	a0,0x3
ffffffffc020497c:	81050513          	addi	a0,a0,-2032 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc0204980:	b0ffb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc0204984:	00003617          	auipc	a2,0x3
ffffffffc0204988:	8a460613          	addi	a2,a2,-1884 # ffffffffc0207228 <default_pmm_manager+0xa70>
ffffffffc020498c:	3ba00593          	li	a1,954
ffffffffc0204990:	00002517          	auipc	a0,0x2
ffffffffc0204994:	7f850513          	addi	a0,a0,2040 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc0204998:	af7fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020499c:	00003697          	auipc	a3,0x3
ffffffffc02049a0:	96468693          	addi	a3,a3,-1692 # ffffffffc0207300 <default_pmm_manager+0xb48>
ffffffffc02049a4:	00002617          	auipc	a2,0x2
ffffffffc02049a8:	a6460613          	addi	a2,a2,-1436 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02049ac:	3c600593          	li	a1,966
ffffffffc02049b0:	00002517          	auipc	a0,0x2
ffffffffc02049b4:	7d850513          	addi	a0,a0,2008 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc02049b8:	ad7fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02049bc:	00003697          	auipc	a3,0x3
ffffffffc02049c0:	91468693          	addi	a3,a3,-1772 # ffffffffc02072d0 <default_pmm_manager+0xb18>
ffffffffc02049c4:	00002617          	auipc	a2,0x2
ffffffffc02049c8:	a4460613          	addi	a2,a2,-1468 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02049cc:	3c500593          	li	a1,965
ffffffffc02049d0:	00002517          	auipc	a0,0x2
ffffffffc02049d4:	7b850513          	addi	a0,a0,1976 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc02049d8:	ab7fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc02049dc:	00003697          	auipc	a3,0x3
ffffffffc02049e0:	8e468693          	addi	a3,a3,-1820 # ffffffffc02072c0 <default_pmm_manager+0xb08>
ffffffffc02049e4:	00002617          	auipc	a2,0x2
ffffffffc02049e8:	a2460613          	addi	a2,a2,-1500 # ffffffffc0206408 <commands+0x8e8>
ffffffffc02049ec:	3c400593          	li	a1,964
ffffffffc02049f0:	00002517          	auipc	a0,0x2
ffffffffc02049f4:	79850513          	addi	a0,a0,1944 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc02049f8:	a97fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02049fc <do_execve>:
{
ffffffffc02049fc:	7171                	addi	sp,sp,-176
ffffffffc02049fe:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204a00:	000a6d97          	auipc	s11,0xa6
ffffffffc0204a04:	d28d8d93          	addi	s11,s11,-728 # ffffffffc02aa728 <current>
ffffffffc0204a08:	000db783          	ld	a5,0(s11)
{
ffffffffc0204a0c:	e54e                	sd	s3,136(sp)
ffffffffc0204a0e:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204a10:	0287b983          	ld	s3,40(a5)
{
ffffffffc0204a14:	e94a                	sd	s2,144(sp)
ffffffffc0204a16:	f4de                	sd	s7,104(sp)
ffffffffc0204a18:	892a                	mv	s2,a0
ffffffffc0204a1a:	8bb2                	mv	s7,a2
ffffffffc0204a1c:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))//检查name的内存空间能否被访问
ffffffffc0204a1e:	862e                	mv	a2,a1
ffffffffc0204a20:	4681                	li	a3,0
ffffffffc0204a22:	85aa                	mv	a1,a0
ffffffffc0204a24:	854e                	mv	a0,s3
{
ffffffffc0204a26:	f506                	sd	ra,168(sp)
ffffffffc0204a28:	f122                	sd	s0,160(sp)
ffffffffc0204a2a:	e152                	sd	s4,128(sp)
ffffffffc0204a2c:	fcd6                	sd	s5,120(sp)
ffffffffc0204a2e:	f8da                	sd	s6,112(sp)
ffffffffc0204a30:	f0e2                	sd	s8,96(sp)
ffffffffc0204a32:	ece6                	sd	s9,88(sp)
ffffffffc0204a34:	e8ea                	sd	s10,80(sp)
ffffffffc0204a36:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))//检查name的内存空间能否被访问
ffffffffc0204a38:	d1aff0ef          	jal	ra,ffffffffc0203f52 <user_mem_check>
ffffffffc0204a3c:	40050a63          	beqz	a0,ffffffffc0204e50 <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204a40:	4641                	li	a2,16
ffffffffc0204a42:	4581                	li	a1,0
ffffffffc0204a44:	1808                	addi	a0,sp,48
ffffffffc0204a46:	643000ef          	jal	ra,ffffffffc0205888 <memset>
    memcpy(local_name, name, len);
ffffffffc0204a4a:	47bd                	li	a5,15
ffffffffc0204a4c:	8626                	mv	a2,s1
ffffffffc0204a4e:	1e97e263          	bltu	a5,s1,ffffffffc0204c32 <do_execve+0x236>
ffffffffc0204a52:	85ca                	mv	a1,s2
ffffffffc0204a54:	1808                	addi	a0,sp,48
ffffffffc0204a56:	645000ef          	jal	ra,ffffffffc020589a <memcpy>
    if (mm != NULL)
ffffffffc0204a5a:	1e098363          	beqz	s3,ffffffffc0204c40 <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc0204a5e:	00002517          	auipc	a0,0x2
ffffffffc0204a62:	4ea50513          	addi	a0,a0,1258 # ffffffffc0206f48 <default_pmm_manager+0x790>
ffffffffc0204a66:	f66fb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc0204a6a:	000a6797          	auipc	a5,0xa6
ffffffffc0204a6e:	c8e7b783          	ld	a5,-882(a5) # ffffffffc02aa6f8 <boot_pgdir_pa>
ffffffffc0204a72:	577d                	li	a4,-1
ffffffffc0204a74:	177e                	slli	a4,a4,0x3f
ffffffffc0204a76:	83b1                	srli	a5,a5,0xc
ffffffffc0204a78:	8fd9                	or	a5,a5,a4
ffffffffc0204a7a:	18079073          	csrw	satp,a5
ffffffffc0204a7e:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b78>
ffffffffc0204a82:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204a86:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204a8a:	2c070463          	beqz	a4,ffffffffc0204d52 <do_execve+0x356>
        current->mm = NULL;
ffffffffc0204a8e:	000db783          	ld	a5,0(s11)
ffffffffc0204a92:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204a96:	e47fe0ef          	jal	ra,ffffffffc02038dc <mm_create>
ffffffffc0204a9a:	84aa                	mv	s1,a0
ffffffffc0204a9c:	1c050d63          	beqz	a0,ffffffffc0204c76 <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204aa0:	4505                	li	a0,1
ffffffffc0204aa2:	ddafd0ef          	jal	ra,ffffffffc020207c <alloc_pages>
ffffffffc0204aa6:	3a050963          	beqz	a0,ffffffffc0204e58 <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc0204aaa:	000a6c97          	auipc	s9,0xa6
ffffffffc0204aae:	c66c8c93          	addi	s9,s9,-922 # ffffffffc02aa710 <pages>
ffffffffc0204ab2:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204ab6:	000a6c17          	auipc	s8,0xa6
ffffffffc0204aba:	c52c0c13          	addi	s8,s8,-942 # ffffffffc02aa708 <npage>
    return page - pages + nbase;
ffffffffc0204abe:	00003717          	auipc	a4,0x3
ffffffffc0204ac2:	f6273703          	ld	a4,-158(a4) # ffffffffc0207a20 <nbase>
ffffffffc0204ac6:	40d506b3          	sub	a3,a0,a3
ffffffffc0204aca:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204acc:	5afd                	li	s5,-1
ffffffffc0204ace:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204ad2:	96ba                	add	a3,a3,a4
ffffffffc0204ad4:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204ad6:	00cad713          	srli	a4,s5,0xc
ffffffffc0204ada:	ec3a                	sd	a4,24(sp)
ffffffffc0204adc:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ade:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204ae0:	38f77063          	bgeu	a4,a5,ffffffffc0204e60 <do_execve+0x464>
ffffffffc0204ae4:	000a6b17          	auipc	s6,0xa6
ffffffffc0204ae8:	c3cb0b13          	addi	s6,s6,-964 # ffffffffc02aa720 <va_pa_offset>
ffffffffc0204aec:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204af0:	6605                	lui	a2,0x1
ffffffffc0204af2:	000a6597          	auipc	a1,0xa6
ffffffffc0204af6:	c0e5b583          	ld	a1,-1010(a1) # ffffffffc02aa700 <boot_pgdir_va>
ffffffffc0204afa:	9936                	add	s2,s2,a3
ffffffffc0204afc:	854a                	mv	a0,s2
ffffffffc0204afe:	59d000ef          	jal	ra,ffffffffc020589a <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204b02:	7782                	ld	a5,32(sp)
ffffffffc0204b04:	4398                	lw	a4,0(a5)
ffffffffc0204b06:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204b0a:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204b0e:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b945f>
ffffffffc0204b12:	14f71863          	bne	a4,a5,ffffffffc0204c62 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204b16:	7682                	ld	a3,32(sp)
ffffffffc0204b18:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204b1c:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204b20:	00371793          	slli	a5,a4,0x3
ffffffffc0204b24:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204b26:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204b28:	078e                	slli	a5,a5,0x3
ffffffffc0204b2a:	97ce                	add	a5,a5,s3
ffffffffc0204b2c:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204b2e:	00f9fc63          	bgeu	s3,a5,ffffffffc0204b46 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204b32:	0009a783          	lw	a5,0(s3)
ffffffffc0204b36:	4705                	li	a4,1
ffffffffc0204b38:	14e78163          	beq	a5,a4,ffffffffc0204c7a <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc0204b3c:	77a2                	ld	a5,40(sp)
ffffffffc0204b3e:	03898993          	addi	s3,s3,56
ffffffffc0204b42:	fef9e8e3          	bltu	s3,a5,ffffffffc0204b32 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204b46:	4701                	li	a4,0
ffffffffc0204b48:	46ad                	li	a3,11
ffffffffc0204b4a:	00100637          	lui	a2,0x100
ffffffffc0204b4e:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204b52:	8526                	mv	a0,s1
ffffffffc0204b54:	f1bfe0ef          	jal	ra,ffffffffc0203a6e <mm_map>
ffffffffc0204b58:	8a2a                	mv	s4,a0
ffffffffc0204b5a:	1e051263          	bnez	a0,ffffffffc0204d3e <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204b5e:	6c88                	ld	a0,24(s1)
ffffffffc0204b60:	467d                	li	a2,31
ffffffffc0204b62:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204b66:	c91fe0ef          	jal	ra,ffffffffc02037f6 <pgdir_alloc_page>
ffffffffc0204b6a:	38050363          	beqz	a0,ffffffffc0204ef0 <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b6e:	6c88                	ld	a0,24(s1)
ffffffffc0204b70:	467d                	li	a2,31
ffffffffc0204b72:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204b76:	c81fe0ef          	jal	ra,ffffffffc02037f6 <pgdir_alloc_page>
ffffffffc0204b7a:	34050b63          	beqz	a0,ffffffffc0204ed0 <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b7e:	6c88                	ld	a0,24(s1)
ffffffffc0204b80:	467d                	li	a2,31
ffffffffc0204b82:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204b86:	c71fe0ef          	jal	ra,ffffffffc02037f6 <pgdir_alloc_page>
ffffffffc0204b8a:	32050363          	beqz	a0,ffffffffc0204eb0 <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b8e:	6c88                	ld	a0,24(s1)
ffffffffc0204b90:	467d                	li	a2,31
ffffffffc0204b92:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204b96:	c61fe0ef          	jal	ra,ffffffffc02037f6 <pgdir_alloc_page>
ffffffffc0204b9a:	2e050b63          	beqz	a0,ffffffffc0204e90 <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204b9e:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0204ba0:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204ba4:	6c94                	ld	a3,24(s1)
ffffffffc0204ba6:	2785                	addiw	a5,a5,1
ffffffffc0204ba8:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0204baa:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204bac:	c02007b7          	lui	a5,0xc0200
ffffffffc0204bb0:	2cf6e463          	bltu	a3,a5,ffffffffc0204e78 <do_execve+0x47c>
ffffffffc0204bb4:	000b3783          	ld	a5,0(s6)
ffffffffc0204bb8:	577d                	li	a4,-1
ffffffffc0204bba:	177e                	slli	a4,a4,0x3f
ffffffffc0204bbc:	8e9d                	sub	a3,a3,a5
ffffffffc0204bbe:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204bc2:	f654                	sd	a3,168(a2)
ffffffffc0204bc4:	8fd9                	or	a5,a5,a4
ffffffffc0204bc6:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204bca:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204bcc:	4581                	li	a1,0
ffffffffc0204bce:	12000613          	li	a2,288
ffffffffc0204bd2:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204bd4:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204bd8:	4b1000ef          	jal	ra,ffffffffc0205888 <memset>
    tf->epc = elf->e_entry;
ffffffffc0204bdc:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bde:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204be2:	edf4f493          	andi	s1,s1,-289
    tf->epc = elf->e_entry;
ffffffffc0204be6:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204be8:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bea:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_exit_out_size+0xffffffff7fff4f94>
    tf->gpr.sp = USTACKTOP;
ffffffffc0204bee:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204bf0:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bf4:	4641                	li	a2,16
ffffffffc0204bf6:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc0204bf8:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0204bfa:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204bfe:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204c02:	854a                	mv	a0,s2
ffffffffc0204c04:	485000ef          	jal	ra,ffffffffc0205888 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204c08:	463d                	li	a2,15
ffffffffc0204c0a:	180c                	addi	a1,sp,48
ffffffffc0204c0c:	854a                	mv	a0,s2
ffffffffc0204c0e:	48d000ef          	jal	ra,ffffffffc020589a <memcpy>
}
ffffffffc0204c12:	70aa                	ld	ra,168(sp)
ffffffffc0204c14:	740a                	ld	s0,160(sp)
ffffffffc0204c16:	64ea                	ld	s1,152(sp)
ffffffffc0204c18:	694a                	ld	s2,144(sp)
ffffffffc0204c1a:	69aa                	ld	s3,136(sp)
ffffffffc0204c1c:	7ae6                	ld	s5,120(sp)
ffffffffc0204c1e:	7b46                	ld	s6,112(sp)
ffffffffc0204c20:	7ba6                	ld	s7,104(sp)
ffffffffc0204c22:	7c06                	ld	s8,96(sp)
ffffffffc0204c24:	6ce6                	ld	s9,88(sp)
ffffffffc0204c26:	6d46                	ld	s10,80(sp)
ffffffffc0204c28:	6da6                	ld	s11,72(sp)
ffffffffc0204c2a:	8552                	mv	a0,s4
ffffffffc0204c2c:	6a0a                	ld	s4,128(sp)
ffffffffc0204c2e:	614d                	addi	sp,sp,176
ffffffffc0204c30:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204c32:	463d                	li	a2,15
ffffffffc0204c34:	85ca                	mv	a1,s2
ffffffffc0204c36:	1808                	addi	a0,sp,48
ffffffffc0204c38:	463000ef          	jal	ra,ffffffffc020589a <memcpy>
    if (mm != NULL)
ffffffffc0204c3c:	e20991e3          	bnez	s3,ffffffffc0204a5e <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204c40:	000db783          	ld	a5,0(s11)
ffffffffc0204c44:	779c                	ld	a5,40(a5)
ffffffffc0204c46:	e40788e3          	beqz	a5,ffffffffc0204a96 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204c4a:	00002617          	auipc	a2,0x2
ffffffffc0204c4e:	70660613          	addi	a2,a2,1798 # ffffffffc0207350 <default_pmm_manager+0xb98>
ffffffffc0204c52:	23f00593          	li	a1,575
ffffffffc0204c56:	00002517          	auipc	a0,0x2
ffffffffc0204c5a:	53250513          	addi	a0,a0,1330 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc0204c5e:	831fb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204c62:	8526                	mv	a0,s1
ffffffffc0204c64:	c88ff0ef          	jal	ra,ffffffffc02040ec <put_pgdir>
    mm_destroy(mm);
ffffffffc0204c68:	8526                	mv	a0,s1
ffffffffc0204c6a:	db3fe0ef          	jal	ra,ffffffffc0203a1c <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204c6e:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc0204c70:	8552                	mv	a0,s4
ffffffffc0204c72:	94bff0ef          	jal	ra,ffffffffc02045bc <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204c76:	5a71                	li	s4,-4
ffffffffc0204c78:	bfe5                	j	ffffffffc0204c70 <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204c7a:	0289b603          	ld	a2,40(s3)
ffffffffc0204c7e:	0209b783          	ld	a5,32(s3)
ffffffffc0204c82:	1cf66d63          	bltu	a2,a5,ffffffffc0204e5c <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204c86:	0049a783          	lw	a5,4(s3)
ffffffffc0204c8a:	0017f693          	andi	a3,a5,1
ffffffffc0204c8e:	c291                	beqz	a3,ffffffffc0204c92 <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204c90:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c92:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c96:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c98:	e779                	bnez	a4,ffffffffc0204d66 <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204c9a:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c9c:	c781                	beqz	a5,ffffffffc0204ca4 <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204c9e:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204ca2:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204ca4:	0026f793          	andi	a5,a3,2
ffffffffc0204ca8:	e3f1                	bnez	a5,ffffffffc0204d6c <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204caa:	0046f793          	andi	a5,a3,4
ffffffffc0204cae:	c399                	beqz	a5,ffffffffc0204cb4 <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204cb0:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204cb4:	0109b583          	ld	a1,16(s3)
ffffffffc0204cb8:	4701                	li	a4,0
ffffffffc0204cba:	8526                	mv	a0,s1
ffffffffc0204cbc:	db3fe0ef          	jal	ra,ffffffffc0203a6e <mm_map>
ffffffffc0204cc0:	8a2a                	mv	s4,a0
ffffffffc0204cc2:	ed35                	bnez	a0,ffffffffc0204d3e <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204cc4:	0109bb83          	ld	s7,16(s3)
ffffffffc0204cc8:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204cca:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204cce:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204cd2:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204cd6:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204cd8:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204cda:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204cdc:	054be963          	bltu	s7,s4,ffffffffc0204d2e <do_execve+0x332>
ffffffffc0204ce0:	aa95                	j	ffffffffc0204e54 <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204ce2:	6785                	lui	a5,0x1
ffffffffc0204ce4:	415b8533          	sub	a0,s7,s5
ffffffffc0204ce8:	9abe                	add	s5,s5,a5
ffffffffc0204cea:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204cee:	015a7463          	bgeu	s4,s5,ffffffffc0204cf6 <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204cf2:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204cf6:	000cb683          	ld	a3,0(s9)
ffffffffc0204cfa:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204cfc:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204d00:	40d406b3          	sub	a3,s0,a3
ffffffffc0204d04:	8699                	srai	a3,a3,0x6
ffffffffc0204d06:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204d08:	67e2                	ld	a5,24(sp)
ffffffffc0204d0a:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d0e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d10:	14b87863          	bgeu	a6,a1,ffffffffc0204e60 <do_execve+0x464>
ffffffffc0204d14:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204d18:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204d1a:	9bb2                	add	s7,s7,a2
ffffffffc0204d1c:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204d1e:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204d20:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204d22:	379000ef          	jal	ra,ffffffffc020589a <memcpy>
            start += size, from += size;
ffffffffc0204d26:	6622                	ld	a2,8(sp)
ffffffffc0204d28:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204d2a:	054bf363          	bgeu	s7,s4,ffffffffc0204d70 <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204d2e:	6c88                	ld	a0,24(s1)
ffffffffc0204d30:	866a                	mv	a2,s10
ffffffffc0204d32:	85d6                	mv	a1,s5
ffffffffc0204d34:	ac3fe0ef          	jal	ra,ffffffffc02037f6 <pgdir_alloc_page>
ffffffffc0204d38:	842a                	mv	s0,a0
ffffffffc0204d3a:	f545                	bnez	a0,ffffffffc0204ce2 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204d3c:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0204d3e:	8526                	mv	a0,s1
ffffffffc0204d40:	e79fe0ef          	jal	ra,ffffffffc0203bb8 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204d44:	8526                	mv	a0,s1
ffffffffc0204d46:	ba6ff0ef          	jal	ra,ffffffffc02040ec <put_pgdir>
    mm_destroy(mm);
ffffffffc0204d4a:	8526                	mv	a0,s1
ffffffffc0204d4c:	cd1fe0ef          	jal	ra,ffffffffc0203a1c <mm_destroy>
    return ret;
ffffffffc0204d50:	b705                	j	ffffffffc0204c70 <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204d52:	854e                	mv	a0,s3
ffffffffc0204d54:	e65fe0ef          	jal	ra,ffffffffc0203bb8 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204d58:	854e                	mv	a0,s3
ffffffffc0204d5a:	b92ff0ef          	jal	ra,ffffffffc02040ec <put_pgdir>
            mm_destroy(mm);//把进程当前占用的内存释放，之后重新分配内存 
ffffffffc0204d5e:	854e                	mv	a0,s3
ffffffffc0204d60:	cbdfe0ef          	jal	ra,ffffffffc0203a1c <mm_destroy>
ffffffffc0204d64:	b32d                	j	ffffffffc0204a8e <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204d66:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204d6a:	fb95                	bnez	a5,ffffffffc0204c9e <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204d6c:	4d5d                	li	s10,23
ffffffffc0204d6e:	bf35                	j	ffffffffc0204caa <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204d70:	0109b683          	ld	a3,16(s3)
ffffffffc0204d74:	0289b903          	ld	s2,40(s3)
ffffffffc0204d78:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204d7a:	075bfd63          	bgeu	s7,s5,ffffffffc0204df4 <do_execve+0x3f8>
            if (start == end)
ffffffffc0204d7e:	db790fe3          	beq	s2,s7,ffffffffc0204b3c <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204d82:	6785                	lui	a5,0x1
ffffffffc0204d84:	00fb8533          	add	a0,s7,a5
ffffffffc0204d88:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204d8c:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204d90:	0b597d63          	bgeu	s2,s5,ffffffffc0204e4a <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204d94:	000cb683          	ld	a3,0(s9)
ffffffffc0204d98:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204d9a:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204d9e:	40d406b3          	sub	a3,s0,a3
ffffffffc0204da2:	8699                	srai	a3,a3,0x6
ffffffffc0204da4:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204da6:	67e2                	ld	a5,24(sp)
ffffffffc0204da8:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204dac:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204dae:	0ac5f963          	bgeu	a1,a2,ffffffffc0204e60 <do_execve+0x464>
ffffffffc0204db2:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204db6:	8652                	mv	a2,s4
ffffffffc0204db8:	4581                	li	a1,0
ffffffffc0204dba:	96c2                	add	a3,a3,a6
ffffffffc0204dbc:	9536                	add	a0,a0,a3
ffffffffc0204dbe:	2cb000ef          	jal	ra,ffffffffc0205888 <memset>
            start += size;
ffffffffc0204dc2:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204dc6:	03597463          	bgeu	s2,s5,ffffffffc0204dee <do_execve+0x3f2>
ffffffffc0204dca:	d6e909e3          	beq	s2,a4,ffffffffc0204b3c <do_execve+0x140>
ffffffffc0204dce:	00002697          	auipc	a3,0x2
ffffffffc0204dd2:	5aa68693          	addi	a3,a3,1450 # ffffffffc0207378 <default_pmm_manager+0xbc0>
ffffffffc0204dd6:	00001617          	auipc	a2,0x1
ffffffffc0204dda:	63260613          	addi	a2,a2,1586 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0204dde:	2a800593          	li	a1,680
ffffffffc0204de2:	00002517          	auipc	a0,0x2
ffffffffc0204de6:	3a650513          	addi	a0,a0,934 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc0204dea:	ea4fb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204dee:	ff5710e3          	bne	a4,s5,ffffffffc0204dce <do_execve+0x3d2>
ffffffffc0204df2:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204df4:	d52bf4e3          	bgeu	s7,s2,ffffffffc0204b3c <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204df8:	6c88                	ld	a0,24(s1)
ffffffffc0204dfa:	866a                	mv	a2,s10
ffffffffc0204dfc:	85d6                	mv	a1,s5
ffffffffc0204dfe:	9f9fe0ef          	jal	ra,ffffffffc02037f6 <pgdir_alloc_page>
ffffffffc0204e02:	842a                	mv	s0,a0
ffffffffc0204e04:	dd05                	beqz	a0,ffffffffc0204d3c <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204e06:	6785                	lui	a5,0x1
ffffffffc0204e08:	415b8533          	sub	a0,s7,s5
ffffffffc0204e0c:	9abe                	add	s5,s5,a5
ffffffffc0204e0e:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204e12:	01597463          	bgeu	s2,s5,ffffffffc0204e1a <do_execve+0x41e>
                size -= la - end;
ffffffffc0204e16:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204e1a:	000cb683          	ld	a3,0(s9)
ffffffffc0204e1e:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204e20:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204e24:	40d406b3          	sub	a3,s0,a3
ffffffffc0204e28:	8699                	srai	a3,a3,0x6
ffffffffc0204e2a:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204e2c:	67e2                	ld	a5,24(sp)
ffffffffc0204e2e:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204e32:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204e34:	02b87663          	bgeu	a6,a1,ffffffffc0204e60 <do_execve+0x464>
ffffffffc0204e38:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204e3c:	4581                	li	a1,0
            start += size;
ffffffffc0204e3e:	9bb2                	add	s7,s7,a2
ffffffffc0204e40:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204e42:	9536                	add	a0,a0,a3
ffffffffc0204e44:	245000ef          	jal	ra,ffffffffc0205888 <memset>
ffffffffc0204e48:	b775                	j	ffffffffc0204df4 <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204e4a:	417a8a33          	sub	s4,s5,s7
ffffffffc0204e4e:	b799                	j	ffffffffc0204d94 <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204e50:	5a75                	li	s4,-3
ffffffffc0204e52:	b3c1                	j	ffffffffc0204c12 <do_execve+0x216>
        while (start < end)
ffffffffc0204e54:	86de                	mv	a3,s7
ffffffffc0204e56:	bf39                	j	ffffffffc0204d74 <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204e58:	5a71                	li	s4,-4
ffffffffc0204e5a:	bdc5                	j	ffffffffc0204d4a <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204e5c:	5a61                	li	s4,-8
ffffffffc0204e5e:	b5c5                	j	ffffffffc0204d3e <do_execve+0x342>
ffffffffc0204e60:	00001617          	auipc	a2,0x1
ffffffffc0204e64:	4e060613          	addi	a2,a2,1248 # ffffffffc0206340 <commands+0x820>
ffffffffc0204e68:	07100593          	li	a1,113
ffffffffc0204e6c:	00001517          	auipc	a0,0x1
ffffffffc0204e70:	48c50513          	addi	a0,a0,1164 # ffffffffc02062f8 <commands+0x7d8>
ffffffffc0204e74:	e1afb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204e78:	00002617          	auipc	a2,0x2
ffffffffc0204e7c:	9e860613          	addi	a2,a2,-1560 # ffffffffc0206860 <default_pmm_manager+0xa8>
ffffffffc0204e80:	2c700593          	li	a1,711
ffffffffc0204e84:	00002517          	auipc	a0,0x2
ffffffffc0204e88:	30450513          	addi	a0,a0,772 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc0204e8c:	e02fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e90:	00002697          	auipc	a3,0x2
ffffffffc0204e94:	60068693          	addi	a3,a3,1536 # ffffffffc0207490 <default_pmm_manager+0xcd8>
ffffffffc0204e98:	00001617          	auipc	a2,0x1
ffffffffc0204e9c:	57060613          	addi	a2,a2,1392 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0204ea0:	2c200593          	li	a1,706
ffffffffc0204ea4:	00002517          	auipc	a0,0x2
ffffffffc0204ea8:	2e450513          	addi	a0,a0,740 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc0204eac:	de2fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204eb0:	00002697          	auipc	a3,0x2
ffffffffc0204eb4:	59868693          	addi	a3,a3,1432 # ffffffffc0207448 <default_pmm_manager+0xc90>
ffffffffc0204eb8:	00001617          	auipc	a2,0x1
ffffffffc0204ebc:	55060613          	addi	a2,a2,1360 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0204ec0:	2c100593          	li	a1,705
ffffffffc0204ec4:	00002517          	auipc	a0,0x2
ffffffffc0204ec8:	2c450513          	addi	a0,a0,708 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc0204ecc:	dc2fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ed0:	00002697          	auipc	a3,0x2
ffffffffc0204ed4:	53068693          	addi	a3,a3,1328 # ffffffffc0207400 <default_pmm_manager+0xc48>
ffffffffc0204ed8:	00001617          	auipc	a2,0x1
ffffffffc0204edc:	53060613          	addi	a2,a2,1328 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0204ee0:	2c000593          	li	a1,704
ffffffffc0204ee4:	00002517          	auipc	a0,0x2
ffffffffc0204ee8:	2a450513          	addi	a0,a0,676 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc0204eec:	da2fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204ef0:	00002697          	auipc	a3,0x2
ffffffffc0204ef4:	4c868693          	addi	a3,a3,1224 # ffffffffc02073b8 <default_pmm_manager+0xc00>
ffffffffc0204ef8:	00001617          	auipc	a2,0x1
ffffffffc0204efc:	51060613          	addi	a2,a2,1296 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0204f00:	2bf00593          	li	a1,703
ffffffffc0204f04:	00002517          	auipc	a0,0x2
ffffffffc0204f08:	28450513          	addi	a0,a0,644 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc0204f0c:	d82fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204f10 <do_yield>:
    current->need_resched = 1;
ffffffffc0204f10:	000a6797          	auipc	a5,0xa6
ffffffffc0204f14:	8187b783          	ld	a5,-2024(a5) # ffffffffc02aa728 <current>
ffffffffc0204f18:	4705                	li	a4,1
ffffffffc0204f1a:	ef98                	sd	a4,24(a5)
}
ffffffffc0204f1c:	4501                	li	a0,0
ffffffffc0204f1e:	8082                	ret

ffffffffc0204f20 <do_wait>:
{
ffffffffc0204f20:	1101                	addi	sp,sp,-32
ffffffffc0204f22:	e822                	sd	s0,16(sp)
ffffffffc0204f24:	e426                	sd	s1,8(sp)
ffffffffc0204f26:	ec06                	sd	ra,24(sp)
ffffffffc0204f28:	842e                	mv	s0,a1
ffffffffc0204f2a:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204f2c:	c999                	beqz	a1,ffffffffc0204f42 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204f2e:	000a5797          	auipc	a5,0xa5
ffffffffc0204f32:	7fa7b783          	ld	a5,2042(a5) # ffffffffc02aa728 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204f36:	7788                	ld	a0,40(a5)
ffffffffc0204f38:	4685                	li	a3,1
ffffffffc0204f3a:	4611                	li	a2,4
ffffffffc0204f3c:	816ff0ef          	jal	ra,ffffffffc0203f52 <user_mem_check>
ffffffffc0204f40:	c909                	beqz	a0,ffffffffc0204f52 <do_wait+0x32>
ffffffffc0204f42:	85a2                	mv	a1,s0
}
ffffffffc0204f44:	6442                	ld	s0,16(sp)
ffffffffc0204f46:	60e2                	ld	ra,24(sp)
ffffffffc0204f48:	8526                	mv	a0,s1
ffffffffc0204f4a:	64a2                	ld	s1,8(sp)
ffffffffc0204f4c:	6105                	addi	sp,sp,32
ffffffffc0204f4e:	fb8ff06f          	j	ffffffffc0204706 <do_wait.part.0>
ffffffffc0204f52:	60e2                	ld	ra,24(sp)
ffffffffc0204f54:	6442                	ld	s0,16(sp)
ffffffffc0204f56:	64a2                	ld	s1,8(sp)
ffffffffc0204f58:	5575                	li	a0,-3
ffffffffc0204f5a:	6105                	addi	sp,sp,32
ffffffffc0204f5c:	8082                	ret

ffffffffc0204f5e <do_kill>:
{
ffffffffc0204f5e:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f60:	6789                	lui	a5,0x2
{
ffffffffc0204f62:	e406                	sd	ra,8(sp)
ffffffffc0204f64:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f66:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204f6a:	17f9                	addi	a5,a5,-2
ffffffffc0204f6c:	02e7e963          	bltu	a5,a4,ffffffffc0204f9e <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f70:	842a                	mv	s0,a0
ffffffffc0204f72:	45a9                	li	a1,10
ffffffffc0204f74:	2501                	sext.w	a0,a0
ffffffffc0204f76:	46c000ef          	jal	ra,ffffffffc02053e2 <hash32>
ffffffffc0204f7a:	02051793          	slli	a5,a0,0x20
ffffffffc0204f7e:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204f82:	000a1797          	auipc	a5,0xa1
ffffffffc0204f86:	73678793          	addi	a5,a5,1846 # ffffffffc02a66b8 <hash_list>
ffffffffc0204f8a:	953e                	add	a0,a0,a5
ffffffffc0204f8c:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204f8e:	a029                	j	ffffffffc0204f98 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204f90:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204f94:	00870b63          	beq	a4,s0,ffffffffc0204faa <do_kill+0x4c>
ffffffffc0204f98:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204f9a:	fef51be3          	bne	a0,a5,ffffffffc0204f90 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204f9e:	5475                	li	s0,-3
}
ffffffffc0204fa0:	60a2                	ld	ra,8(sp)
ffffffffc0204fa2:	8522                	mv	a0,s0
ffffffffc0204fa4:	6402                	ld	s0,0(sp)
ffffffffc0204fa6:	0141                	addi	sp,sp,16
ffffffffc0204fa8:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204faa:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204fae:	00177693          	andi	a3,a4,1
ffffffffc0204fb2:	e295                	bnez	a3,ffffffffc0204fd6 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204fb4:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204fb6:	00176713          	ori	a4,a4,1
ffffffffc0204fba:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204fbe:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204fc0:	fe06d0e3          	bgez	a3,ffffffffc0204fa0 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204fc4:	f2878513          	addi	a0,a5,-216
ffffffffc0204fc8:	22e000ef          	jal	ra,ffffffffc02051f6 <wakeup_proc>
}
ffffffffc0204fcc:	60a2                	ld	ra,8(sp)
ffffffffc0204fce:	8522                	mv	a0,s0
ffffffffc0204fd0:	6402                	ld	s0,0(sp)
ffffffffc0204fd2:	0141                	addi	sp,sp,16
ffffffffc0204fd4:	8082                	ret
        return -E_KILLED;
ffffffffc0204fd6:	545d                	li	s0,-9
ffffffffc0204fd8:	b7e1                	j	ffffffffc0204fa0 <do_kill+0x42>

ffffffffc0204fda <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204fda:	1101                	addi	sp,sp,-32
ffffffffc0204fdc:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204fde:	000a5797          	auipc	a5,0xa5
ffffffffc0204fe2:	6da78793          	addi	a5,a5,1754 # ffffffffc02aa6b8 <proc_list>
ffffffffc0204fe6:	ec06                	sd	ra,24(sp)
ffffffffc0204fe8:	e822                	sd	s0,16(sp)
ffffffffc0204fea:	e04a                	sd	s2,0(sp)
ffffffffc0204fec:	000a1497          	auipc	s1,0xa1
ffffffffc0204ff0:	6cc48493          	addi	s1,s1,1740 # ffffffffc02a66b8 <hash_list>
ffffffffc0204ff4:	e79c                	sd	a5,8(a5)
ffffffffc0204ff6:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204ff8:	000a5717          	auipc	a4,0xa5
ffffffffc0204ffc:	6c070713          	addi	a4,a4,1728 # ffffffffc02aa6b8 <proc_list>
ffffffffc0205000:	87a6                	mv	a5,s1
ffffffffc0205002:	e79c                	sd	a5,8(a5)
ffffffffc0205004:	e39c                	sd	a5,0(a5)
ffffffffc0205006:	07c1                	addi	a5,a5,16
ffffffffc0205008:	fef71de3          	bne	a4,a5,ffffffffc0205002 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc020500c:	fe3fe0ef          	jal	ra,ffffffffc0203fee <alloc_proc>
ffffffffc0205010:	000a5917          	auipc	s2,0xa5
ffffffffc0205014:	72090913          	addi	s2,s2,1824 # ffffffffc02aa730 <idleproc>
ffffffffc0205018:	00a93023          	sd	a0,0(s2)
ffffffffc020501c:	0e050f63          	beqz	a0,ffffffffc020511a <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205020:	4789                	li	a5,2
ffffffffc0205022:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205024:	00003797          	auipc	a5,0x3
ffffffffc0205028:	fdc78793          	addi	a5,a5,-36 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020502c:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205030:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0205032:	4785                	li	a5,1
ffffffffc0205034:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205036:	4641                	li	a2,16
ffffffffc0205038:	4581                	li	a1,0
ffffffffc020503a:	8522                	mv	a0,s0
ffffffffc020503c:	04d000ef          	jal	ra,ffffffffc0205888 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205040:	463d                	li	a2,15
ffffffffc0205042:	00002597          	auipc	a1,0x2
ffffffffc0205046:	4ae58593          	addi	a1,a1,1198 # ffffffffc02074f0 <default_pmm_manager+0xd38>
ffffffffc020504a:	8522                	mv	a0,s0
ffffffffc020504c:	04f000ef          	jal	ra,ffffffffc020589a <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0205050:	000a5717          	auipc	a4,0xa5
ffffffffc0205054:	6f070713          	addi	a4,a4,1776 # ffffffffc02aa740 <nr_process>
ffffffffc0205058:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc020505a:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);//创建一个内核进程执行init_main()函数
ffffffffc020505e:	4601                	li	a2,0
    nr_process++;
ffffffffc0205060:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);//创建一个内核进程执行init_main()函数
ffffffffc0205062:	4581                	li	a1,0
ffffffffc0205064:	00000517          	auipc	a0,0x0
ffffffffc0205068:	87450513          	addi	a0,a0,-1932 # ffffffffc02048d8 <init_main>
    nr_process++;
ffffffffc020506c:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc020506e:	000a5797          	auipc	a5,0xa5
ffffffffc0205072:	6ad7bd23          	sd	a3,1722(a5) # ffffffffc02aa728 <current>
    int pid = kernel_thread(init_main, NULL, 0);//创建一个内核进程执行init_main()函数
ffffffffc0205076:	cf6ff0ef          	jal	ra,ffffffffc020456c <kernel_thread>
ffffffffc020507a:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc020507c:	08a05363          	blez	a0,ffffffffc0205102 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0205080:	6789                	lui	a5,0x2
ffffffffc0205082:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205086:	17f9                	addi	a5,a5,-2
ffffffffc0205088:	2501                	sext.w	a0,a0
ffffffffc020508a:	02e7e363          	bltu	a5,a4,ffffffffc02050b0 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020508e:	45a9                	li	a1,10
ffffffffc0205090:	352000ef          	jal	ra,ffffffffc02053e2 <hash32>
ffffffffc0205094:	02051793          	slli	a5,a0,0x20
ffffffffc0205098:	01c7d693          	srli	a3,a5,0x1c
ffffffffc020509c:	96a6                	add	a3,a3,s1
ffffffffc020509e:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc02050a0:	a029                	j	ffffffffc02050aa <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc02050a2:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c7c>
ffffffffc02050a6:	04870b63          	beq	a4,s0,ffffffffc02050fc <proc_init+0x122>
    return listelm->next;
ffffffffc02050aa:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02050ac:	fef69be3          	bne	a3,a5,ffffffffc02050a2 <proc_init+0xc8>
    return NULL;
ffffffffc02050b0:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050b2:	0b478493          	addi	s1,a5,180
ffffffffc02050b6:	4641                	li	a2,16
ffffffffc02050b8:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc02050ba:	000a5417          	auipc	s0,0xa5
ffffffffc02050be:	67e40413          	addi	s0,s0,1662 # ffffffffc02aa738 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050c2:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc02050c4:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050c6:	7c2000ef          	jal	ra,ffffffffc0205888 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02050ca:	463d                	li	a2,15
ffffffffc02050cc:	00002597          	auipc	a1,0x2
ffffffffc02050d0:	44c58593          	addi	a1,a1,1100 # ffffffffc0207518 <default_pmm_manager+0xd60>
ffffffffc02050d4:	8526                	mv	a0,s1
ffffffffc02050d6:	7c4000ef          	jal	ra,ffffffffc020589a <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02050da:	00093783          	ld	a5,0(s2)
ffffffffc02050de:	cbb5                	beqz	a5,ffffffffc0205152 <proc_init+0x178>
ffffffffc02050e0:	43dc                	lw	a5,4(a5)
ffffffffc02050e2:	eba5                	bnez	a5,ffffffffc0205152 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02050e4:	601c                	ld	a5,0(s0)
ffffffffc02050e6:	c7b1                	beqz	a5,ffffffffc0205132 <proc_init+0x158>
ffffffffc02050e8:	43d8                	lw	a4,4(a5)
ffffffffc02050ea:	4785                	li	a5,1
ffffffffc02050ec:	04f71363          	bne	a4,a5,ffffffffc0205132 <proc_init+0x158>
}
ffffffffc02050f0:	60e2                	ld	ra,24(sp)
ffffffffc02050f2:	6442                	ld	s0,16(sp)
ffffffffc02050f4:	64a2                	ld	s1,8(sp)
ffffffffc02050f6:	6902                	ld	s2,0(sp)
ffffffffc02050f8:	6105                	addi	sp,sp,32
ffffffffc02050fa:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02050fc:	f2878793          	addi	a5,a5,-216
ffffffffc0205100:	bf4d                	j	ffffffffc02050b2 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0205102:	00002617          	auipc	a2,0x2
ffffffffc0205106:	3f660613          	addi	a2,a2,1014 # ffffffffc02074f8 <default_pmm_manager+0xd40>
ffffffffc020510a:	3e900593          	li	a1,1001
ffffffffc020510e:	00002517          	auipc	a0,0x2
ffffffffc0205112:	07a50513          	addi	a0,a0,122 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc0205116:	b78fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc020511a:	00002617          	auipc	a2,0x2
ffffffffc020511e:	3be60613          	addi	a2,a2,958 # ffffffffc02074d8 <default_pmm_manager+0xd20>
ffffffffc0205122:	3da00593          	li	a1,986
ffffffffc0205126:	00002517          	auipc	a0,0x2
ffffffffc020512a:	06250513          	addi	a0,a0,98 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc020512e:	b60fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205132:	00002697          	auipc	a3,0x2
ffffffffc0205136:	41668693          	addi	a3,a3,1046 # ffffffffc0207548 <default_pmm_manager+0xd90>
ffffffffc020513a:	00001617          	auipc	a2,0x1
ffffffffc020513e:	2ce60613          	addi	a2,a2,718 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0205142:	3f000593          	li	a1,1008
ffffffffc0205146:	00002517          	auipc	a0,0x2
ffffffffc020514a:	04250513          	addi	a0,a0,66 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc020514e:	b40fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205152:	00002697          	auipc	a3,0x2
ffffffffc0205156:	3ce68693          	addi	a3,a3,974 # ffffffffc0207520 <default_pmm_manager+0xd68>
ffffffffc020515a:	00001617          	auipc	a2,0x1
ffffffffc020515e:	2ae60613          	addi	a2,a2,686 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0205162:	3ef00593          	li	a1,1007
ffffffffc0205166:	00002517          	auipc	a0,0x2
ffffffffc020516a:	02250513          	addi	a0,a0,34 # ffffffffc0207188 <default_pmm_manager+0x9d0>
ffffffffc020516e:	b20fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205172 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0205172:	1141                	addi	sp,sp,-16
ffffffffc0205174:	e022                	sd	s0,0(sp)
ffffffffc0205176:	e406                	sd	ra,8(sp)
ffffffffc0205178:	000a5417          	auipc	s0,0xa5
ffffffffc020517c:	5b040413          	addi	s0,s0,1456 # ffffffffc02aa728 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205180:	6018                	ld	a4,0(s0)
ffffffffc0205182:	6f1c                	ld	a5,24(a4)
ffffffffc0205184:	dffd                	beqz	a5,ffffffffc0205182 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0205186:	0f0000ef          	jal	ra,ffffffffc0205276 <schedule>
ffffffffc020518a:	bfdd                	j	ffffffffc0205180 <cpu_idle+0xe>

ffffffffc020518c <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc020518c:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205190:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205194:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205196:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205198:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc020519c:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02051a0:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02051a4:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02051a8:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02051ac:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02051b0:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02051b4:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02051b8:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02051bc:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02051c0:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02051c4:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02051c8:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02051ca:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02051cc:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02051d0:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02051d4:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02051d8:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02051dc:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02051e0:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02051e4:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02051e8:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02051ec:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02051f0:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02051f4:	8082                	ret

ffffffffc02051f6 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051f6:	4118                	lw	a4,0(a0)
{
ffffffffc02051f8:	1101                	addi	sp,sp,-32
ffffffffc02051fa:	ec06                	sd	ra,24(sp)
ffffffffc02051fc:	e822                	sd	s0,16(sp)
ffffffffc02051fe:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205200:	478d                	li	a5,3
ffffffffc0205202:	04f70b63          	beq	a4,a5,ffffffffc0205258 <wakeup_proc+0x62>
ffffffffc0205206:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205208:	100027f3          	csrr	a5,sstatus
ffffffffc020520c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020520e:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205210:	ef9d                	bnez	a5,ffffffffc020524e <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205212:	4789                	li	a5,2
ffffffffc0205214:	02f70163          	beq	a4,a5,ffffffffc0205236 <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc0205218:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc020521a:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc020521e:	e491                	bnez	s1,ffffffffc020522a <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205220:	60e2                	ld	ra,24(sp)
ffffffffc0205222:	6442                	ld	s0,16(sp)
ffffffffc0205224:	64a2                	ld	s1,8(sp)
ffffffffc0205226:	6105                	addi	sp,sp,32
ffffffffc0205228:	8082                	ret
ffffffffc020522a:	6442                	ld	s0,16(sp)
ffffffffc020522c:	60e2                	ld	ra,24(sp)
ffffffffc020522e:	64a2                	ld	s1,8(sp)
ffffffffc0205230:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205232:	f7cfb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205236:	00002617          	auipc	a2,0x2
ffffffffc020523a:	37260613          	addi	a2,a2,882 # ffffffffc02075a8 <default_pmm_manager+0xdf0>
ffffffffc020523e:	45d1                	li	a1,20
ffffffffc0205240:	00002517          	auipc	a0,0x2
ffffffffc0205244:	35050513          	addi	a0,a0,848 # ffffffffc0207590 <default_pmm_manager+0xdd8>
ffffffffc0205248:	aaefb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc020524c:	bfc9                	j	ffffffffc020521e <wakeup_proc+0x28>
        intr_disable();
ffffffffc020524e:	f66fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205252:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0205254:	4485                	li	s1,1
ffffffffc0205256:	bf75                	j	ffffffffc0205212 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205258:	00002697          	auipc	a3,0x2
ffffffffc020525c:	31868693          	addi	a3,a3,792 # ffffffffc0207570 <default_pmm_manager+0xdb8>
ffffffffc0205260:	00001617          	auipc	a2,0x1
ffffffffc0205264:	1a860613          	addi	a2,a2,424 # ffffffffc0206408 <commands+0x8e8>
ffffffffc0205268:	45a5                	li	a1,9
ffffffffc020526a:	00002517          	auipc	a0,0x2
ffffffffc020526e:	32650513          	addi	a0,a0,806 # ffffffffc0207590 <default_pmm_manager+0xdd8>
ffffffffc0205272:	a1cfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205276 <schedule>:

void schedule(void)
{
ffffffffc0205276:	1141                	addi	sp,sp,-16
ffffffffc0205278:	e406                	sd	ra,8(sp)
ffffffffc020527a:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020527c:	100027f3          	csrr	a5,sstatus
ffffffffc0205280:	8b89                	andi	a5,a5,2
ffffffffc0205282:	4401                	li	s0,0
ffffffffc0205284:	efbd                	bnez	a5,ffffffffc0205302 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205286:	000a5897          	auipc	a7,0xa5
ffffffffc020528a:	4a28b883          	ld	a7,1186(a7) # ffffffffc02aa728 <current>
ffffffffc020528e:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205292:	000a5517          	auipc	a0,0xa5
ffffffffc0205296:	49e53503          	ld	a0,1182(a0) # ffffffffc02aa730 <idleproc>
ffffffffc020529a:	04a88e63          	beq	a7,a0,ffffffffc02052f6 <schedule+0x80>
ffffffffc020529e:	0c888693          	addi	a3,a7,200
ffffffffc02052a2:	000a5617          	auipc	a2,0xa5
ffffffffc02052a6:	41660613          	addi	a2,a2,1046 # ffffffffc02aa6b8 <proc_list>
        le = last;
ffffffffc02052aa:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02052ac:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc02052ae:	4809                	li	a6,2
ffffffffc02052b0:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02052b2:	00c78863          	beq	a5,a2,ffffffffc02052c2 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc02052b6:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02052ba:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc02052be:	03070163          	beq	a4,a6,ffffffffc02052e0 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc02052c2:	fef697e3          	bne	a3,a5,ffffffffc02052b0 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02052c6:	ed89                	bnez	a1,ffffffffc02052e0 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02052c8:	451c                	lw	a5,8(a0)
ffffffffc02052ca:	2785                	addiw	a5,a5,1
ffffffffc02052cc:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc02052ce:	00a88463          	beq	a7,a0,ffffffffc02052d6 <schedule+0x60>
        {
            proc_run(next);
ffffffffc02052d2:	e91fe0ef          	jal	ra,ffffffffc0204162 <proc_run>
    if (flag)
ffffffffc02052d6:	e819                	bnez	s0,ffffffffc02052ec <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02052d8:	60a2                	ld	ra,8(sp)
ffffffffc02052da:	6402                	ld	s0,0(sp)
ffffffffc02052dc:	0141                	addi	sp,sp,16
ffffffffc02052de:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02052e0:	4198                	lw	a4,0(a1)
ffffffffc02052e2:	4789                	li	a5,2
ffffffffc02052e4:	fef712e3          	bne	a4,a5,ffffffffc02052c8 <schedule+0x52>
ffffffffc02052e8:	852e                	mv	a0,a1
ffffffffc02052ea:	bff9                	j	ffffffffc02052c8 <schedule+0x52>
}
ffffffffc02052ec:	6402                	ld	s0,0(sp)
ffffffffc02052ee:	60a2                	ld	ra,8(sp)
ffffffffc02052f0:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02052f2:	ebcfb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02052f6:	000a5617          	auipc	a2,0xa5
ffffffffc02052fa:	3c260613          	addi	a2,a2,962 # ffffffffc02aa6b8 <proc_list>
ffffffffc02052fe:	86b2                	mv	a3,a2
ffffffffc0205300:	b76d                	j	ffffffffc02052aa <schedule+0x34>
        intr_disable();
ffffffffc0205302:	eb2fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0205306:	4405                	li	s0,1
ffffffffc0205308:	bfbd                	j	ffffffffc0205286 <schedule+0x10>

ffffffffc020530a <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc020530a:	000a5797          	auipc	a5,0xa5
ffffffffc020530e:	41e7b783          	ld	a5,1054(a5) # ffffffffc02aa728 <current>
}
ffffffffc0205312:	43c8                	lw	a0,4(a5)
ffffffffc0205314:	8082                	ret

ffffffffc0205316 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205316:	4501                	li	a0,0
ffffffffc0205318:	8082                	ret

ffffffffc020531a <sys_putc>:
    cputchar(c);
ffffffffc020531a:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc020531c:	1141                	addi	sp,sp,-16
ffffffffc020531e:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205320:	eabfa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc0205324:	60a2                	ld	ra,8(sp)
ffffffffc0205326:	4501                	li	a0,0
ffffffffc0205328:	0141                	addi	sp,sp,16
ffffffffc020532a:	8082                	ret

ffffffffc020532c <sys_kill>:
    return do_kill(pid);
ffffffffc020532c:	4108                	lw	a0,0(a0)
ffffffffc020532e:	c31ff06f          	j	ffffffffc0204f5e <do_kill>

ffffffffc0205332 <sys_yield>:
    return do_yield();
ffffffffc0205332:	bdfff06f          	j	ffffffffc0204f10 <do_yield>

ffffffffc0205336 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205336:	6d14                	ld	a3,24(a0)
ffffffffc0205338:	6910                	ld	a2,16(a0)
ffffffffc020533a:	650c                	ld	a1,8(a0)
ffffffffc020533c:	6108                	ld	a0,0(a0)
ffffffffc020533e:	ebeff06f          	j	ffffffffc02049fc <do_execve>

ffffffffc0205342 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205342:	650c                	ld	a1,8(a0)
ffffffffc0205344:	4108                	lw	a0,0(a0)
ffffffffc0205346:	bdbff06f          	j	ffffffffc0204f20 <do_wait>

ffffffffc020534a <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc020534a:	000a5797          	auipc	a5,0xa5
ffffffffc020534e:	3de7b783          	ld	a5,990(a5) # ffffffffc02aa728 <current>
ffffffffc0205352:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205354:	4501                	li	a0,0
ffffffffc0205356:	6a0c                	ld	a1,16(a2)
ffffffffc0205358:	e6ffe06f          	j	ffffffffc02041c6 <do_fork>

ffffffffc020535c <sys_exit>:
    return do_exit(error_code);
ffffffffc020535c:	4108                	lw	a0,0(a0)
ffffffffc020535e:	a5eff06f          	j	ffffffffc02045bc <do_exit>

ffffffffc0205362 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205362:	715d                	addi	sp,sp,-80
ffffffffc0205364:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205366:	000a5497          	auipc	s1,0xa5
ffffffffc020536a:	3c248493          	addi	s1,s1,962 # ffffffffc02aa728 <current>
ffffffffc020536e:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0205370:	e0a2                	sd	s0,64(sp)
ffffffffc0205372:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205374:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205376:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205378:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc020537a:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020537e:	0327ee63          	bltu	a5,s2,ffffffffc02053ba <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc0205382:	00391713          	slli	a4,s2,0x3
ffffffffc0205386:	00002797          	auipc	a5,0x2
ffffffffc020538a:	28a78793          	addi	a5,a5,650 # ffffffffc0207610 <syscalls>
ffffffffc020538e:	97ba                	add	a5,a5,a4
ffffffffc0205390:	639c                	ld	a5,0(a5)
ffffffffc0205392:	c785                	beqz	a5,ffffffffc02053ba <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc0205394:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0205396:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205398:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc020539a:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc020539c:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc020539e:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc02053a0:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc02053a2:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc02053a4:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc02053a6:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02053a8:	0028                	addi	a0,sp,8
ffffffffc02053aa:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02053ac:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02053ae:	e828                	sd	a0,80(s0)
}
ffffffffc02053b0:	6406                	ld	s0,64(sp)
ffffffffc02053b2:	74e2                	ld	s1,56(sp)
ffffffffc02053b4:	7942                	ld	s2,48(sp)
ffffffffc02053b6:	6161                	addi	sp,sp,80
ffffffffc02053b8:	8082                	ret
    print_trapframe(tf);
ffffffffc02053ba:	8522                	mv	a0,s0
ffffffffc02053bc:	fe8fb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02053c0:	609c                	ld	a5,0(s1)
ffffffffc02053c2:	86ca                	mv	a3,s2
ffffffffc02053c4:	00002617          	auipc	a2,0x2
ffffffffc02053c8:	20460613          	addi	a2,a2,516 # ffffffffc02075c8 <default_pmm_manager+0xe10>
ffffffffc02053cc:	43d8                	lw	a4,4(a5)
ffffffffc02053ce:	06200593          	li	a1,98
ffffffffc02053d2:	0b478793          	addi	a5,a5,180
ffffffffc02053d6:	00002517          	auipc	a0,0x2
ffffffffc02053da:	22250513          	addi	a0,a0,546 # ffffffffc02075f8 <default_pmm_manager+0xe40>
ffffffffc02053de:	8b0fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02053e2 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02053e2:	9e3707b7          	lui	a5,0x9e370
ffffffffc02053e6:	2785                	addiw	a5,a5,1
ffffffffc02053e8:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02053ec:	02000793          	li	a5,32
ffffffffc02053f0:	9f8d                	subw	a5,a5,a1
}
ffffffffc02053f2:	00f5553b          	srlw	a0,a0,a5
ffffffffc02053f6:	8082                	ret

ffffffffc02053f8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02053f8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053fc:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02053fe:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205402:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205404:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205408:	f022                	sd	s0,32(sp)
ffffffffc020540a:	ec26                	sd	s1,24(sp)
ffffffffc020540c:	e84a                	sd	s2,16(sp)
ffffffffc020540e:	f406                	sd	ra,40(sp)
ffffffffc0205410:	e44e                	sd	s3,8(sp)
ffffffffc0205412:	84aa                	mv	s1,a0
ffffffffc0205414:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205416:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020541a:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020541c:	03067e63          	bgeu	a2,a6,ffffffffc0205458 <printnum+0x60>
ffffffffc0205420:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205422:	00805763          	blez	s0,ffffffffc0205430 <printnum+0x38>
ffffffffc0205426:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205428:	85ca                	mv	a1,s2
ffffffffc020542a:	854e                	mv	a0,s3
ffffffffc020542c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020542e:	fc65                	bnez	s0,ffffffffc0205426 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205430:	1a02                	slli	s4,s4,0x20
ffffffffc0205432:	00002797          	auipc	a5,0x2
ffffffffc0205436:	2de78793          	addi	a5,a5,734 # ffffffffc0207710 <syscalls+0x100>
ffffffffc020543a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020543e:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205440:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205442:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0205446:	70a2                	ld	ra,40(sp)
ffffffffc0205448:	69a2                	ld	s3,8(sp)
ffffffffc020544a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020544c:	85ca                	mv	a1,s2
ffffffffc020544e:	87a6                	mv	a5,s1
}
ffffffffc0205450:	6942                	ld	s2,16(sp)
ffffffffc0205452:	64e2                	ld	s1,24(sp)
ffffffffc0205454:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205456:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205458:	03065633          	divu	a2,a2,a6
ffffffffc020545c:	8722                	mv	a4,s0
ffffffffc020545e:	f9bff0ef          	jal	ra,ffffffffc02053f8 <printnum>
ffffffffc0205462:	b7f9                	j	ffffffffc0205430 <printnum+0x38>

ffffffffc0205464 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205464:	7119                	addi	sp,sp,-128
ffffffffc0205466:	f4a6                	sd	s1,104(sp)
ffffffffc0205468:	f0ca                	sd	s2,96(sp)
ffffffffc020546a:	ecce                	sd	s3,88(sp)
ffffffffc020546c:	e8d2                	sd	s4,80(sp)
ffffffffc020546e:	e4d6                	sd	s5,72(sp)
ffffffffc0205470:	e0da                	sd	s6,64(sp)
ffffffffc0205472:	fc5e                	sd	s7,56(sp)
ffffffffc0205474:	f06a                	sd	s10,32(sp)
ffffffffc0205476:	fc86                	sd	ra,120(sp)
ffffffffc0205478:	f8a2                	sd	s0,112(sp)
ffffffffc020547a:	f862                	sd	s8,48(sp)
ffffffffc020547c:	f466                	sd	s9,40(sp)
ffffffffc020547e:	ec6e                	sd	s11,24(sp)
ffffffffc0205480:	892a                	mv	s2,a0
ffffffffc0205482:	84ae                	mv	s1,a1
ffffffffc0205484:	8d32                	mv	s10,a2
ffffffffc0205486:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205488:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020548c:	5b7d                	li	s6,-1
ffffffffc020548e:	00002a97          	auipc	s5,0x2
ffffffffc0205492:	2aea8a93          	addi	s5,s5,686 # ffffffffc020773c <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205496:	00002b97          	auipc	s7,0x2
ffffffffc020549a:	4c2b8b93          	addi	s7,s7,1218 # ffffffffc0207958 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020549e:	000d4503          	lbu	a0,0(s10)
ffffffffc02054a2:	001d0413          	addi	s0,s10,1
ffffffffc02054a6:	01350a63          	beq	a0,s3,ffffffffc02054ba <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02054aa:	c121                	beqz	a0,ffffffffc02054ea <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02054ac:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02054ae:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02054b0:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02054b2:	fff44503          	lbu	a0,-1(s0)
ffffffffc02054b6:	ff351ae3          	bne	a0,s3,ffffffffc02054aa <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054ba:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02054be:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02054c2:	4c81                	li	s9,0
ffffffffc02054c4:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02054c6:	5c7d                	li	s8,-1
ffffffffc02054c8:	5dfd                	li	s11,-1
ffffffffc02054ca:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02054ce:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054d0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02054d4:	0ff5f593          	zext.b	a1,a1
ffffffffc02054d8:	00140d13          	addi	s10,s0,1
ffffffffc02054dc:	04b56263          	bltu	a0,a1,ffffffffc0205520 <vprintfmt+0xbc>
ffffffffc02054e0:	058a                	slli	a1,a1,0x2
ffffffffc02054e2:	95d6                	add	a1,a1,s5
ffffffffc02054e4:	4194                	lw	a3,0(a1)
ffffffffc02054e6:	96d6                	add	a3,a3,s5
ffffffffc02054e8:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02054ea:	70e6                	ld	ra,120(sp)
ffffffffc02054ec:	7446                	ld	s0,112(sp)
ffffffffc02054ee:	74a6                	ld	s1,104(sp)
ffffffffc02054f0:	7906                	ld	s2,96(sp)
ffffffffc02054f2:	69e6                	ld	s3,88(sp)
ffffffffc02054f4:	6a46                	ld	s4,80(sp)
ffffffffc02054f6:	6aa6                	ld	s5,72(sp)
ffffffffc02054f8:	6b06                	ld	s6,64(sp)
ffffffffc02054fa:	7be2                	ld	s7,56(sp)
ffffffffc02054fc:	7c42                	ld	s8,48(sp)
ffffffffc02054fe:	7ca2                	ld	s9,40(sp)
ffffffffc0205500:	7d02                	ld	s10,32(sp)
ffffffffc0205502:	6de2                	ld	s11,24(sp)
ffffffffc0205504:	6109                	addi	sp,sp,128
ffffffffc0205506:	8082                	ret
            padc = '0';
ffffffffc0205508:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc020550a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020550e:	846a                	mv	s0,s10
ffffffffc0205510:	00140d13          	addi	s10,s0,1
ffffffffc0205514:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205518:	0ff5f593          	zext.b	a1,a1
ffffffffc020551c:	fcb572e3          	bgeu	a0,a1,ffffffffc02054e0 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0205520:	85a6                	mv	a1,s1
ffffffffc0205522:	02500513          	li	a0,37
ffffffffc0205526:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205528:	fff44783          	lbu	a5,-1(s0)
ffffffffc020552c:	8d22                	mv	s10,s0
ffffffffc020552e:	f73788e3          	beq	a5,s3,ffffffffc020549e <vprintfmt+0x3a>
ffffffffc0205532:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0205536:	1d7d                	addi	s10,s10,-1
ffffffffc0205538:	ff379de3          	bne	a5,s3,ffffffffc0205532 <vprintfmt+0xce>
ffffffffc020553c:	b78d                	j	ffffffffc020549e <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020553e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0205542:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205546:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0205548:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020554c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205550:	02d86463          	bltu	a6,a3,ffffffffc0205578 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0205554:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205558:	002c169b          	slliw	a3,s8,0x2
ffffffffc020555c:	0186873b          	addw	a4,a3,s8
ffffffffc0205560:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205564:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205566:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020556a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020556c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205570:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205574:	fed870e3          	bgeu	a6,a3,ffffffffc0205554 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205578:	f40ddce3          	bgez	s11,ffffffffc02054d0 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020557c:	8de2                	mv	s11,s8
ffffffffc020557e:	5c7d                	li	s8,-1
ffffffffc0205580:	bf81                	j	ffffffffc02054d0 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205582:	fffdc693          	not	a3,s11
ffffffffc0205586:	96fd                	srai	a3,a3,0x3f
ffffffffc0205588:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020558c:	00144603          	lbu	a2,1(s0)
ffffffffc0205590:	2d81                	sext.w	s11,s11
ffffffffc0205592:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205594:	bf35                	j	ffffffffc02054d0 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205596:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020559a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020559e:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055a0:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02055a2:	bfd9                	j	ffffffffc0205578 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02055a4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055a6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055aa:	01174463          	blt	a4,a7,ffffffffc02055b2 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02055ae:	1a088e63          	beqz	a7,ffffffffc020576a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02055b2:	000a3603          	ld	a2,0(s4)
ffffffffc02055b6:	46c1                	li	a3,16
ffffffffc02055b8:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02055ba:	2781                	sext.w	a5,a5
ffffffffc02055bc:	876e                	mv	a4,s11
ffffffffc02055be:	85a6                	mv	a1,s1
ffffffffc02055c0:	854a                	mv	a0,s2
ffffffffc02055c2:	e37ff0ef          	jal	ra,ffffffffc02053f8 <printnum>
            break;
ffffffffc02055c6:	bde1                	j	ffffffffc020549e <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02055c8:	000a2503          	lw	a0,0(s4)
ffffffffc02055cc:	85a6                	mv	a1,s1
ffffffffc02055ce:	0a21                	addi	s4,s4,8
ffffffffc02055d0:	9902                	jalr	s2
            break;
ffffffffc02055d2:	b5f1                	j	ffffffffc020549e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02055d4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055d6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055da:	01174463          	blt	a4,a7,ffffffffc02055e2 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02055de:	18088163          	beqz	a7,ffffffffc0205760 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02055e2:	000a3603          	ld	a2,0(s4)
ffffffffc02055e6:	46a9                	li	a3,10
ffffffffc02055e8:	8a2e                	mv	s4,a1
ffffffffc02055ea:	bfc1                	j	ffffffffc02055ba <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055ec:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02055f0:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055f2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02055f4:	bdf1                	j	ffffffffc02054d0 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02055f6:	85a6                	mv	a1,s1
ffffffffc02055f8:	02500513          	li	a0,37
ffffffffc02055fc:	9902                	jalr	s2
            break;
ffffffffc02055fe:	b545                	j	ffffffffc020549e <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205600:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0205604:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205606:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205608:	b5e1                	j	ffffffffc02054d0 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc020560a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020560c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205610:	01174463          	blt	a4,a7,ffffffffc0205618 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0205614:	14088163          	beqz	a7,ffffffffc0205756 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0205618:	000a3603          	ld	a2,0(s4)
ffffffffc020561c:	46a1                	li	a3,8
ffffffffc020561e:	8a2e                	mv	s4,a1
ffffffffc0205620:	bf69                	j	ffffffffc02055ba <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0205622:	03000513          	li	a0,48
ffffffffc0205626:	85a6                	mv	a1,s1
ffffffffc0205628:	e03e                	sd	a5,0(sp)
ffffffffc020562a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020562c:	85a6                	mv	a1,s1
ffffffffc020562e:	07800513          	li	a0,120
ffffffffc0205632:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205634:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205636:	6782                	ld	a5,0(sp)
ffffffffc0205638:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020563a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020563e:	bfb5                	j	ffffffffc02055ba <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205640:	000a3403          	ld	s0,0(s4)
ffffffffc0205644:	008a0713          	addi	a4,s4,8
ffffffffc0205648:	e03a                	sd	a4,0(sp)
ffffffffc020564a:	14040263          	beqz	s0,ffffffffc020578e <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020564e:	0fb05763          	blez	s11,ffffffffc020573c <vprintfmt+0x2d8>
ffffffffc0205652:	02d00693          	li	a3,45
ffffffffc0205656:	0cd79163          	bne	a5,a3,ffffffffc0205718 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020565a:	00044783          	lbu	a5,0(s0)
ffffffffc020565e:	0007851b          	sext.w	a0,a5
ffffffffc0205662:	cf85                	beqz	a5,ffffffffc020569a <vprintfmt+0x236>
ffffffffc0205664:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205668:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020566c:	000c4563          	bltz	s8,ffffffffc0205676 <vprintfmt+0x212>
ffffffffc0205670:	3c7d                	addiw	s8,s8,-1
ffffffffc0205672:	036c0263          	beq	s8,s6,ffffffffc0205696 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205676:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205678:	0e0c8e63          	beqz	s9,ffffffffc0205774 <vprintfmt+0x310>
ffffffffc020567c:	3781                	addiw	a5,a5,-32
ffffffffc020567e:	0ef47b63          	bgeu	s0,a5,ffffffffc0205774 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205682:	03f00513          	li	a0,63
ffffffffc0205686:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205688:	000a4783          	lbu	a5,0(s4)
ffffffffc020568c:	3dfd                	addiw	s11,s11,-1
ffffffffc020568e:	0a05                	addi	s4,s4,1
ffffffffc0205690:	0007851b          	sext.w	a0,a5
ffffffffc0205694:	ffe1                	bnez	a5,ffffffffc020566c <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205696:	01b05963          	blez	s11,ffffffffc02056a8 <vprintfmt+0x244>
ffffffffc020569a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020569c:	85a6                	mv	a1,s1
ffffffffc020569e:	02000513          	li	a0,32
ffffffffc02056a2:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02056a4:	fe0d9be3          	bnez	s11,ffffffffc020569a <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02056a8:	6a02                	ld	s4,0(sp)
ffffffffc02056aa:	bbd5                	j	ffffffffc020549e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02056ac:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02056ae:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02056b2:	01174463          	blt	a4,a7,ffffffffc02056ba <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02056b6:	08088d63          	beqz	a7,ffffffffc0205750 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02056ba:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02056be:	0a044d63          	bltz	s0,ffffffffc0205778 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02056c2:	8622                	mv	a2,s0
ffffffffc02056c4:	8a66                	mv	s4,s9
ffffffffc02056c6:	46a9                	li	a3,10
ffffffffc02056c8:	bdcd                	j	ffffffffc02055ba <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02056ca:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056ce:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02056d0:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02056d2:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02056d6:	8fb5                	xor	a5,a5,a3
ffffffffc02056d8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056dc:	02d74163          	blt	a4,a3,ffffffffc02056fe <vprintfmt+0x29a>
ffffffffc02056e0:	00369793          	slli	a5,a3,0x3
ffffffffc02056e4:	97de                	add	a5,a5,s7
ffffffffc02056e6:	639c                	ld	a5,0(a5)
ffffffffc02056e8:	cb99                	beqz	a5,ffffffffc02056fe <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02056ea:	86be                	mv	a3,a5
ffffffffc02056ec:	00000617          	auipc	a2,0x0
ffffffffc02056f0:	1f460613          	addi	a2,a2,500 # ffffffffc02058e0 <etext+0x2e>
ffffffffc02056f4:	85a6                	mv	a1,s1
ffffffffc02056f6:	854a                	mv	a0,s2
ffffffffc02056f8:	0ce000ef          	jal	ra,ffffffffc02057c6 <printfmt>
ffffffffc02056fc:	b34d                	j	ffffffffc020549e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02056fe:	00002617          	auipc	a2,0x2
ffffffffc0205702:	03260613          	addi	a2,a2,50 # ffffffffc0207730 <syscalls+0x120>
ffffffffc0205706:	85a6                	mv	a1,s1
ffffffffc0205708:	854a                	mv	a0,s2
ffffffffc020570a:	0bc000ef          	jal	ra,ffffffffc02057c6 <printfmt>
ffffffffc020570e:	bb41                	j	ffffffffc020549e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205710:	00002417          	auipc	s0,0x2
ffffffffc0205714:	01840413          	addi	s0,s0,24 # ffffffffc0207728 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205718:	85e2                	mv	a1,s8
ffffffffc020571a:	8522                	mv	a0,s0
ffffffffc020571c:	e43e                	sd	a5,8(sp)
ffffffffc020571e:	0e2000ef          	jal	ra,ffffffffc0205800 <strnlen>
ffffffffc0205722:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0205726:	01b05b63          	blez	s11,ffffffffc020573c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020572a:	67a2                	ld	a5,8(sp)
ffffffffc020572c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205730:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205732:	85a6                	mv	a1,s1
ffffffffc0205734:	8552                	mv	a0,s4
ffffffffc0205736:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205738:	fe0d9ce3          	bnez	s11,ffffffffc0205730 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020573c:	00044783          	lbu	a5,0(s0)
ffffffffc0205740:	00140a13          	addi	s4,s0,1
ffffffffc0205744:	0007851b          	sext.w	a0,a5
ffffffffc0205748:	d3a5                	beqz	a5,ffffffffc02056a8 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020574a:	05e00413          	li	s0,94
ffffffffc020574e:	bf39                	j	ffffffffc020566c <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205750:	000a2403          	lw	s0,0(s4)
ffffffffc0205754:	b7ad                	j	ffffffffc02056be <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205756:	000a6603          	lwu	a2,0(s4)
ffffffffc020575a:	46a1                	li	a3,8
ffffffffc020575c:	8a2e                	mv	s4,a1
ffffffffc020575e:	bdb1                	j	ffffffffc02055ba <vprintfmt+0x156>
ffffffffc0205760:	000a6603          	lwu	a2,0(s4)
ffffffffc0205764:	46a9                	li	a3,10
ffffffffc0205766:	8a2e                	mv	s4,a1
ffffffffc0205768:	bd89                	j	ffffffffc02055ba <vprintfmt+0x156>
ffffffffc020576a:	000a6603          	lwu	a2,0(s4)
ffffffffc020576e:	46c1                	li	a3,16
ffffffffc0205770:	8a2e                	mv	s4,a1
ffffffffc0205772:	b5a1                	j	ffffffffc02055ba <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205774:	9902                	jalr	s2
ffffffffc0205776:	bf09                	j	ffffffffc0205688 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205778:	85a6                	mv	a1,s1
ffffffffc020577a:	02d00513          	li	a0,45
ffffffffc020577e:	e03e                	sd	a5,0(sp)
ffffffffc0205780:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205782:	6782                	ld	a5,0(sp)
ffffffffc0205784:	8a66                	mv	s4,s9
ffffffffc0205786:	40800633          	neg	a2,s0
ffffffffc020578a:	46a9                	li	a3,10
ffffffffc020578c:	b53d                	j	ffffffffc02055ba <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020578e:	03b05163          	blez	s11,ffffffffc02057b0 <vprintfmt+0x34c>
ffffffffc0205792:	02d00693          	li	a3,45
ffffffffc0205796:	f6d79de3          	bne	a5,a3,ffffffffc0205710 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020579a:	00002417          	auipc	s0,0x2
ffffffffc020579e:	f8e40413          	addi	s0,s0,-114 # ffffffffc0207728 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02057a2:	02800793          	li	a5,40
ffffffffc02057a6:	02800513          	li	a0,40
ffffffffc02057aa:	00140a13          	addi	s4,s0,1
ffffffffc02057ae:	bd6d                	j	ffffffffc0205668 <vprintfmt+0x204>
ffffffffc02057b0:	00002a17          	auipc	s4,0x2
ffffffffc02057b4:	f79a0a13          	addi	s4,s4,-135 # ffffffffc0207729 <syscalls+0x119>
ffffffffc02057b8:	02800513          	li	a0,40
ffffffffc02057bc:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02057c0:	05e00413          	li	s0,94
ffffffffc02057c4:	b565                	j	ffffffffc020566c <vprintfmt+0x208>

ffffffffc02057c6 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057c6:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02057c8:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057cc:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057ce:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057d0:	ec06                	sd	ra,24(sp)
ffffffffc02057d2:	f83a                	sd	a4,48(sp)
ffffffffc02057d4:	fc3e                	sd	a5,56(sp)
ffffffffc02057d6:	e0c2                	sd	a6,64(sp)
ffffffffc02057d8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02057da:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057dc:	c89ff0ef          	jal	ra,ffffffffc0205464 <vprintfmt>
}
ffffffffc02057e0:	60e2                	ld	ra,24(sp)
ffffffffc02057e2:	6161                	addi	sp,sp,80
ffffffffc02057e4:	8082                	ret

ffffffffc02057e6 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02057e6:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02057ea:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02057ec:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02057ee:	cb81                	beqz	a5,ffffffffc02057fe <strlen+0x18>
        cnt ++;
ffffffffc02057f0:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02057f2:	00a707b3          	add	a5,a4,a0
ffffffffc02057f6:	0007c783          	lbu	a5,0(a5)
ffffffffc02057fa:	fbfd                	bnez	a5,ffffffffc02057f0 <strlen+0xa>
ffffffffc02057fc:	8082                	ret
    }
    return cnt;
}
ffffffffc02057fe:	8082                	ret

ffffffffc0205800 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205800:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205802:	e589                	bnez	a1,ffffffffc020580c <strnlen+0xc>
ffffffffc0205804:	a811                	j	ffffffffc0205818 <strnlen+0x18>
        cnt ++;
ffffffffc0205806:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205808:	00f58863          	beq	a1,a5,ffffffffc0205818 <strnlen+0x18>
ffffffffc020580c:	00f50733          	add	a4,a0,a5
ffffffffc0205810:	00074703          	lbu	a4,0(a4)
ffffffffc0205814:	fb6d                	bnez	a4,ffffffffc0205806 <strnlen+0x6>
ffffffffc0205816:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205818:	852e                	mv	a0,a1
ffffffffc020581a:	8082                	ret

ffffffffc020581c <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc020581c:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc020581e:	0005c703          	lbu	a4,0(a1)
ffffffffc0205822:	0785                	addi	a5,a5,1
ffffffffc0205824:	0585                	addi	a1,a1,1
ffffffffc0205826:	fee78fa3          	sb	a4,-1(a5)
ffffffffc020582a:	fb75                	bnez	a4,ffffffffc020581e <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc020582c:	8082                	ret

ffffffffc020582e <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020582e:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205832:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205836:	cb89                	beqz	a5,ffffffffc0205848 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205838:	0505                	addi	a0,a0,1
ffffffffc020583a:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020583c:	fee789e3          	beq	a5,a4,ffffffffc020582e <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205840:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205844:	9d19                	subw	a0,a0,a4
ffffffffc0205846:	8082                	ret
ffffffffc0205848:	4501                	li	a0,0
ffffffffc020584a:	bfed                	j	ffffffffc0205844 <strcmp+0x16>

ffffffffc020584c <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020584c:	c20d                	beqz	a2,ffffffffc020586e <strncmp+0x22>
ffffffffc020584e:	962e                	add	a2,a2,a1
ffffffffc0205850:	a031                	j	ffffffffc020585c <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205852:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205854:	00e79a63          	bne	a5,a4,ffffffffc0205868 <strncmp+0x1c>
ffffffffc0205858:	00b60b63          	beq	a2,a1,ffffffffc020586e <strncmp+0x22>
ffffffffc020585c:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205860:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205862:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205866:	f7f5                	bnez	a5,ffffffffc0205852 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205868:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020586c:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020586e:	4501                	li	a0,0
ffffffffc0205870:	8082                	ret

ffffffffc0205872 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205872:	00054783          	lbu	a5,0(a0)
ffffffffc0205876:	c799                	beqz	a5,ffffffffc0205884 <strchr+0x12>
        if (*s == c) {
ffffffffc0205878:	00f58763          	beq	a1,a5,ffffffffc0205886 <strchr+0x14>
    while (*s != '\0') {
ffffffffc020587c:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205880:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205882:	fbfd                	bnez	a5,ffffffffc0205878 <strchr+0x6>
    }
    return NULL;
ffffffffc0205884:	4501                	li	a0,0
}
ffffffffc0205886:	8082                	ret

ffffffffc0205888 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205888:	ca01                	beqz	a2,ffffffffc0205898 <memset+0x10>
ffffffffc020588a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020588c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020588e:	0785                	addi	a5,a5,1
ffffffffc0205890:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205894:	fec79de3          	bne	a5,a2,ffffffffc020588e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205898:	8082                	ret

ffffffffc020589a <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc020589a:	ca19                	beqz	a2,ffffffffc02058b0 <memcpy+0x16>
ffffffffc020589c:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc020589e:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02058a0:	0005c703          	lbu	a4,0(a1)
ffffffffc02058a4:	0585                	addi	a1,a1,1
ffffffffc02058a6:	0785                	addi	a5,a5,1
ffffffffc02058a8:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02058ac:	fec59ae3          	bne	a1,a2,ffffffffc02058a0 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02058b0:	8082                	ret
