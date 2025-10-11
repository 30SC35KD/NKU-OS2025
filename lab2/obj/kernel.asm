
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00005297          	auipc	t0,0x5
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0205000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00005297          	auipc	t0,0x5
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0205008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02042b7          	lui	t0,0xc0204
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
ffffffffc020003c:	c0204137          	lui	sp,0xc0204

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	4b450513          	addi	a0,a0,1204 # ffffffffc0201500 <etext>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	4be50513          	addi	a0,a0,1214 # ffffffffc0201520 <etext+0x20>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	49258593          	addi	a1,a1,1170 # ffffffffc0201500 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	4ca50513          	addi	a0,a0,1226 # ffffffffc0201540 <etext+0x40>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00005597          	auipc	a1,0x5
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0205018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	4d650513          	addi	a0,a0,1238 # ffffffffc0201560 <etext+0x60>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00005597          	auipc	a1,0x5
ffffffffc020009a:	0aa58593          	addi	a1,a1,170 # ffffffffc0205140 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	4e250513          	addi	a0,a0,1250 # ffffffffc0201580 <etext+0x80>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00005597          	auipc	a1,0x5
ffffffffc02000ae:	49558593          	addi	a1,a1,1173 # ffffffffc020553f <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00001517          	auipc	a0,0x1
ffffffffc02000d0:	4d450513          	addi	a0,a0,1236 # ffffffffc02015a0 <etext+0xa0>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00005517          	auipc	a0,0x5
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0205018 <free_area>
ffffffffc02000e0:	00005617          	auipc	a2,0x5
ffffffffc02000e4:	06060613          	addi	a2,a2,96 # ffffffffc0205140 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	3fe010ef          	jal	ra,ffffffffc02014ee <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00001517          	auipc	a0,0x1
ffffffffc0200100:	4d450513          	addi	a0,a0,1236 # ffffffffc02015d0 <etext+0xd0>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	589000ef          	jal	ra,ffffffffc0200e94 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	799000ef          	jal	ra,ffffffffc02010d8 <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0204028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	763000ef          	jal	ra,ffffffffc02010d8 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00005317          	auipc	t1,0x5
ffffffffc02001c6:	f3630313          	addi	t1,t1,-202 # ffffffffc02050f8 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00001517          	auipc	a0,0x1
ffffffffc02001f6:	3fe50513          	addi	a0,a0,1022 # ffffffffc02015f0 <etext+0xf0>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00001517          	auipc	a0,0x1
ffffffffc020020c:	3c050513          	addi	a0,a0,960 # ffffffffc02015c8 <etext+0xc8>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	23e0106f          	j	ffffffffc020145a <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00001517          	auipc	a0,0x1
ffffffffc0200226:	3ee50513          	addi	a0,a0,1006 # ffffffffc0201610 <etext+0x110>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00005597          	auipc	a1,0x5
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0205000 <boot_hartid>
ffffffffc0200250:	00001517          	auipc	a0,0x1
ffffffffc0200254:	3d050513          	addi	a0,a0,976 # ffffffffc0201620 <etext+0x120>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00005417          	auipc	s0,0x5
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0205008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	3ca50513          	addi	a0,a0,970 # ffffffffc0201630 <etext+0x130>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00001517          	auipc	a0,0x1
ffffffffc020027a:	3d250513          	addi	a0,a0,978 # ffffffffc0201648 <etext+0x148>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfedadad>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00001917          	auipc	s2,0x1
ffffffffc0200334:	36890913          	addi	s2,s2,872 # ffffffffc0201698 <etext+0x198>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00001497          	auipc	s1,0x1
ffffffffc0200342:	35248493          	addi	s1,s1,850 # ffffffffc0201690 <etext+0x190>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00001517          	auipc	a0,0x1
ffffffffc0200396:	37e50513          	addi	a0,a0,894 # ffffffffc0201710 <etext+0x210>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	3aa50513          	addi	a0,a0,938 # ffffffffc0201748 <etext+0x248>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	28a50513          	addi	a0,a0,650 # ffffffffc0201668 <etext+0x168>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	088010ef          	jal	ra,ffffffffc0201474 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	0ce010ef          	jal	ra,ffffffffc02014c8 <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	01a010ef          	jal	ra,ffffffffc02014aa <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00001517          	auipc	a0,0x1
ffffffffc02004a8:	1fc50513          	addi	a0,a0,508 # ffffffffc02016a0 <etext+0x1a0>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00001517          	auipc	a0,0x1
ffffffffc0200576:	14e50513          	addi	a0,a0,334 # ffffffffc02016c0 <etext+0x1c0>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	15450513          	addi	a0,a0,340 # ffffffffc02016d8 <etext+0x1d8>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	16250513          	addi	a0,a0,354 # ffffffffc02016f8 <etext+0x1f8>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	1a650513          	addi	a0,a0,422 # ffffffffc0201748 <etext+0x248>
        memory_base = mem_base;
ffffffffc02005aa:	00005797          	auipc	a5,0x5
ffffffffc02005ae:	b487bb23          	sd	s0,-1194(a5) # ffffffffc0205100 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00005797          	auipc	a5,0x5
ffffffffc02005b6:	b567bb23          	sd	s6,-1194(a5) # ffffffffc0205108 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00005517          	auipc	a0,0x5
ffffffffc02005c0:	b4453503          	ld	a0,-1212(a0) # ffffffffc0205100 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00005517          	auipc	a0,0x5
ffffffffc02005ca:	b4253503          	ld	a0,-1214(a0) # ffffffffc0205108 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <buddy_init>:

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)
static void
buddy_init(void) {
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc02005d0:	00005717          	auipc	a4,0x5
ffffffffc02005d4:	af870713          	addi	a4,a4,-1288 # ffffffffc02050c8 <free_area+0xb0>
ffffffffc02005d8:	00005797          	auipc	a5,0x5
ffffffffc02005dc:	a4078793          	addi	a5,a5,-1472 # ffffffffc0205018 <free_area>
ffffffffc02005e0:	86ba                	mv	a3,a4
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005e2:	e79c                	sd	a5,8(a5)
ffffffffc02005e4:	e39c                	sd	a5,0(a5)
        list_init(&free_list[i]);
        nr_free[i]=0;
ffffffffc02005e6:	00072023          	sw	zero,0(a4)
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc02005ea:	07c1                	addi	a5,a5,16
ffffffffc02005ec:	0711                	addi	a4,a4,4
ffffffffc02005ee:	fed79ae3          	bne	a5,a3,ffffffffc02005e2 <buddy_init+0x12>
    }
}
ffffffffc02005f2:	8082                	ret

ffffffffc02005f4 <buddy_nr_free_pages>:
}

static size_t
buddy_nr_free_pages(void) {
    size_t total = 0;
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc02005f4:	00005697          	auipc	a3,0x5
ffffffffc02005f8:	ad468693          	addi	a3,a3,-1324 # ffffffffc02050c8 <free_area+0xb0>
ffffffffc02005fc:	4701                	li	a4,0
    size_t total = 0;
ffffffffc02005fe:	4501                	li	a0,0
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc0200600:	462d                	li	a2,11
        total += nr_free[order] * (1U << order);
ffffffffc0200602:	429c                	lw	a5,0(a3)
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc0200604:	0691                	addi	a3,a3,4
        total += nr_free[order] * (1U << order);
ffffffffc0200606:	00e797bb          	sllw	a5,a5,a4
ffffffffc020060a:	1782                	slli	a5,a5,0x20
ffffffffc020060c:	9381                	srli	a5,a5,0x20
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc020060e:	2705                	addiw	a4,a4,1
        total += nr_free[order] * (1U << order);
ffffffffc0200610:	953e                	add	a0,a0,a5
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc0200612:	fec718e3          	bne	a4,a2,ffffffffc0200602 <buddy_nr_free_pages+0xe>
    }
    return total;
}
ffffffffc0200616:	8082                	ret

ffffffffc0200618 <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0200618:	1101                	addi	sp,sp,-32
ffffffffc020061a:	e822                	sd	s0,16(sp)
ffffffffc020061c:	e04a                	sd	s2,0(sp)
ffffffffc020061e:	842e                	mv	s0,a1
ffffffffc0200620:	892a                	mv	s2,a0
    cprintf("buddy_init_memmap: base %p, n %lu\n", base, n);
ffffffffc0200622:	862e                	mv	a2,a1
ffffffffc0200624:	85aa                	mv	a1,a0
ffffffffc0200626:	00001517          	auipc	a0,0x1
ffffffffc020062a:	13a50513          	addi	a0,a0,314 # ffffffffc0201760 <etext+0x260>
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc020062e:	ec06                	sd	ra,24(sp)
ffffffffc0200630:	e426                	sd	s1,8(sp)
    cprintf("buddy_init_memmap: base %p, n %lu\n", base, n);
ffffffffc0200632:	b1bff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(n > 0);
ffffffffc0200636:	c079                	beqz	s0,ffffffffc02006fc <buddy_init_memmap+0xe4>
    size_t idx = p - pages;  // 当前页号
ffffffffc0200638:	00005497          	auipc	s1,0x5
ffffffffc020063c:	ae04b483          	ld	s1,-1312(s1) # ffffffffc0205118 <pages>
ffffffffc0200640:	409904b3          	sub	s1,s2,s1
ffffffffc0200644:	00002797          	auipc	a5,0x2
ffffffffc0200648:	82c7b783          	ld	a5,-2004(a5) # ffffffffc0201e70 <error_string+0x38>
ffffffffc020064c:	848d                	srai	s1,s1,0x3
ffffffffc020064e:	02f484b3          	mul	s1,s1,a5
    cprintf("Starting idx: %d\n", idx);
ffffffffc0200652:	00001517          	auipc	a0,0x1
ffffffffc0200656:	16e50513          	addi	a0,a0,366 # ffffffffc02017c0 <etext+0x2c0>
ffffffffc020065a:	85a6                	mv	a1,s1
ffffffffc020065c:	af1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (left > 0) {
ffffffffc0200660:	00005597          	auipc	a1,0x5
ffffffffc0200664:	9b858593          	addi	a1,a1,-1608 # ffffffffc0205018 <free_area>
        while ((1U << order) > left)
ffffffffc0200668:	3ff00893          	li	a7,1023
ffffffffc020066c:	4805                	li	a6,1
        SetPageProperty(p);
ffffffffc020066e:	4509                	li	a0,2
        int order = MAX_ORDER - 1;
ffffffffc0200670:	4729                	li	a4,10
        while ((1U << order) > left)
ffffffffc0200672:	3ff00693          	li	a3,1023
ffffffffc0200676:	40000793          	li	a5,1024
ffffffffc020067a:	0288e263          	bltu	a7,s0,ffffffffc020069e <buddy_init_memmap+0x86>
            order--;
ffffffffc020067e:	377d                	addiw	a4,a4,-1
        while ((1U << order) > left)
ffffffffc0200680:	00e817bb          	sllw	a5,a6,a4
ffffffffc0200684:	02079693          	slli	a3,a5,0x20
ffffffffc0200688:	9281                	srli	a3,a3,0x20
ffffffffc020068a:	fed46ae3          	bltu	s0,a3,ffffffffc020067e <buddy_init_memmap+0x66>
ffffffffc020068e:	a021                	j	ffffffffc0200696 <buddy_init_memmap+0x7e>
            order--;
ffffffffc0200690:	377d                	addiw	a4,a4,-1
        while (idx & ((1U << order) - 1))
ffffffffc0200692:	00e817bb          	sllw	a5,a6,a4
ffffffffc0200696:	fff7869b          	addiw	a3,a5,-1
ffffffffc020069a:	1682                	slli	a3,a3,0x20
ffffffffc020069c:	9281                	srli	a3,a3,0x20
ffffffffc020069e:	8ee5                	and	a3,a3,s1
ffffffffc02006a0:	fae5                	bnez	a3,ffffffffc0200690 <buddy_init_memmap+0x78>
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
ffffffffc02006a2:	00471613          	slli	a2,a4,0x4
        nr_free[order]++;
ffffffffc02006a6:	02c70713          	addi	a4,a4,44
ffffffffc02006aa:	962e                	add	a2,a2,a1
ffffffffc02006ac:	070a                	slli	a4,a4,0x2
ffffffffc02006ae:	00063e03          	ld	t3,0(a2) # ff0000 <kern_entry-0xffffffffbf210000>
ffffffffc02006b2:	972e                	add	a4,a4,a1
ffffffffc02006b4:	00072303          	lw	t1,0(a4)
        p->property = 1U << order;
ffffffffc02006b8:	00f92823          	sw	a5,16(s2)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02006bc:	00092023          	sw	zero,0(s2)
        SetPageProperty(p);
ffffffffc02006c0:	00a93423          	sd	a0,8(s2)
        list_add_before(&free_list[order], &(p->page_link));
ffffffffc02006c4:	01890693          	addi	a3,s2,24
        p += (1U << order);
ffffffffc02006c8:	1782                	slli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02006ca:	e214                	sd	a3,0(a2)
ffffffffc02006cc:	9381                	srli	a5,a5,0x20
ffffffffc02006ce:	00de3423          	sd	a3,8(t3)
ffffffffc02006d2:	00279693          	slli	a3,a5,0x2
    elm->next = next;
ffffffffc02006d6:	02c93023          	sd	a2,32(s2)
    elm->prev = prev;
ffffffffc02006da:	01c93c23          	sd	t3,24(s2)
        nr_free[order]++;
ffffffffc02006de:	0013061b          	addiw	a2,t1,1
        p += (1U << order);
ffffffffc02006e2:	96be                	add	a3,a3,a5
ffffffffc02006e4:	068e                	slli	a3,a3,0x3
        nr_free[order]++;
ffffffffc02006e6:	c310                	sw	a2,0(a4)
        left -= (1U << order);
ffffffffc02006e8:	8c1d                	sub	s0,s0,a5
        p += (1U << order);
ffffffffc02006ea:	9936                	add	s2,s2,a3
        idx += (1U << order);
ffffffffc02006ec:	94be                	add	s1,s1,a5
    while (left > 0) {
ffffffffc02006ee:	f049                	bnez	s0,ffffffffc0200670 <buddy_init_memmap+0x58>
}
ffffffffc02006f0:	60e2                	ld	ra,24(sp)
ffffffffc02006f2:	6442                	ld	s0,16(sp)
ffffffffc02006f4:	64a2                	ld	s1,8(sp)
ffffffffc02006f6:	6902                	ld	s2,0(sp)
ffffffffc02006f8:	6105                	addi	sp,sp,32
ffffffffc02006fa:	8082                	ret
    assert(n > 0);
ffffffffc02006fc:	00001697          	auipc	a3,0x1
ffffffffc0200700:	08c68693          	addi	a3,a3,140 # ffffffffc0201788 <etext+0x288>
ffffffffc0200704:	00001617          	auipc	a2,0x1
ffffffffc0200708:	08c60613          	addi	a2,a2,140 # ffffffffc0201790 <etext+0x290>
ffffffffc020070c:	45d9                	li	a1,22
ffffffffc020070e:	00001517          	auipc	a0,0x1
ffffffffc0200712:	09a50513          	addi	a0,a0,154 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200716:	aadff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020071a <buddy_free_pages.part.0>:
    while (size < n) {
ffffffffc020071a:	4785                	li	a5,1
ffffffffc020071c:	0cb7f863          	bgeu	a5,a1,ffffffffc02007ec <buddy_free_pages.part.0+0xd2>
    int order = 0;
ffffffffc0200720:	4681                	li	a3,0
        size <<= 1;
ffffffffc0200722:	0786                	slli	a5,a5,0x1
        order++;
ffffffffc0200724:	2685                	addiw	a3,a3,1
    while (size < n) {
ffffffffc0200726:	feb7eee3          	bltu	a5,a1,ffffffffc0200722 <buddy_free_pages.part.0+0x8>
        nr_free[order]--;
ffffffffc020072a:	02c68793          	addi	a5,a3,44
ffffffffc020072e:	00005e17          	auipc	t3,0x5
ffffffffc0200732:	8eae0e13          	addi	t3,t3,-1814 # ffffffffc0205018 <free_area>
ffffffffc0200736:	00279713          	slli	a4,a5,0x2
ffffffffc020073a:	9772                	add	a4,a4,t3
    while (order < MAX_ORDER-1) {
ffffffffc020073c:	4625                	li	a2,9
        nr_free[order]--;
ffffffffc020073e:	00072803          	lw	a6,0(a4)
    while (order < MAX_ORDER-1) {
ffffffffc0200742:	0ad64d63          	blt	a2,a3,ffffffffc02007fc <buddy_free_pages.part.0+0xe2>
ffffffffc0200746:	02c6859b          	addiw	a1,a3,44
ffffffffc020074a:	058a                	slli	a1,a1,0x2
        size_t idx = page - pages;
ffffffffc020074c:	00005897          	auipc	a7,0x5
ffffffffc0200750:	9cc8b883          	ld	a7,-1588(a7) # ffffffffc0205118 <pages>
ffffffffc0200754:	95f2                	add	a1,a1,t3
ffffffffc0200756:	00001f17          	auipc	t5,0x1
ffffffffc020075a:	71af3f03          	ld	t5,1818(t5) # ffffffffc0201e70 <error_string+0x38>
        size_t block_size = 1U << order;
ffffffffc020075e:	4e85                	li	t4,1
    while (order < MAX_ORDER-1) {
ffffffffc0200760:	4fa9                	li	t6,10
ffffffffc0200762:	a01d                	j	ffffffffc0200788 <buddy_free_pages.part.0+0x6e>
        if (!(PageProperty(buddy) && buddy->property == block_size)) {
ffffffffc0200764:	4b98                	lw	a4,16(a5)
ffffffffc0200766:	04c71663          	bne	a4,a2,ffffffffc02007b2 <buddy_free_pages.part.0+0x98>
    __list_del(listelm->prev, listelm->next);
ffffffffc020076a:	6f90                	ld	a2,24(a5)
ffffffffc020076c:	7398                	ld	a4,32(a5)
        order++; 
ffffffffc020076e:	2685                	addiw	a3,a3,1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200770:	e618                	sd	a4,8(a2)
    next->prev = prev;
ffffffffc0200772:	e310                	sd	a2,0(a4)
        nr_free[order]--;
ffffffffc0200774:	0065a023          	sw	t1,0(a1)
        if (buddy < page) {
ffffffffc0200778:	00a7f363          	bgeu	a5,a0,ffffffffc020077e <buddy_free_pages.part.0+0x64>
ffffffffc020077c:	853e                	mv	a0,a5
    while (order < MAX_ORDER-1) {
ffffffffc020077e:	0591                	addi	a1,a1,4
ffffffffc0200780:	07f68163          	beq	a3,t6,ffffffffc02007e2 <buddy_free_pages.part.0+0xc8>
        nr_free[order]--;
ffffffffc0200784:	0005a803          	lw	a6,0(a1)
        size_t idx = page - pages;
ffffffffc0200788:	411507b3          	sub	a5,a0,a7
ffffffffc020078c:	878d                	srai	a5,a5,0x3
ffffffffc020078e:	03e787b3          	mul	a5,a5,t5
        size_t block_size = 1U << order;
ffffffffc0200792:	00de963b          	sllw	a2,t4,a3
ffffffffc0200796:	02061713          	slli	a4,a2,0x20
ffffffffc020079a:	9301                	srli	a4,a4,0x20
        nr_free[order]--;
ffffffffc020079c:	fff8031b          	addiw	t1,a6,-1
        size_t buddy_idx = idx ^ block_size; 
ffffffffc02007a0:	8f3d                	xor	a4,a4,a5
        struct Page *buddy = &pages[buddy_idx];
ffffffffc02007a2:	00271793          	slli	a5,a4,0x2
ffffffffc02007a6:	97ba                	add	a5,a5,a4
ffffffffc02007a8:	078e                	slli	a5,a5,0x3
ffffffffc02007aa:	97c6                	add	a5,a5,a7
        if (!(PageProperty(buddy) && buddy->property == block_size)) {
ffffffffc02007ac:	6798                	ld	a4,8(a5)
ffffffffc02007ae:	8b09                	andi	a4,a4,2
ffffffffc02007b0:	fb55                	bnez	a4,ffffffffc0200764 <buddy_free_pages.part.0+0x4a>
ffffffffc02007b2:	02c68793          	addi	a5,a3,44
    SetPageProperty(page);
ffffffffc02007b6:	6518                	ld	a4,8(a0)
    __list_add(elm, listelm, listelm->next);
ffffffffc02007b8:	0692                	slli	a3,a3,0x4
ffffffffc02007ba:	96f2                	add	a3,a3,t3
ffffffffc02007bc:	668c                	ld	a1,8(a3)
ffffffffc02007be:	00276713          	ori	a4,a4,2
ffffffffc02007c2:	e518                	sd	a4,8(a0)
    page->property = 1U << order;
ffffffffc02007c4:	c910                	sw	a2,16(a0)
ffffffffc02007c6:	00052023          	sw	zero,0(a0)
    list_add(le, &(page->page_link));
ffffffffc02007ca:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02007ce:	e198                	sd	a4,0(a1)
ffffffffc02007d0:	e698                	sd	a4,8(a3)
    nr_free[order]++;
ffffffffc02007d2:	078a                	slli	a5,a5,0x2
    elm->next = next;
ffffffffc02007d4:	f10c                	sd	a1,32(a0)
    elm->prev = prev;
ffffffffc02007d6:	ed14                	sd	a3,24(a0)
ffffffffc02007d8:	9e3e                	add	t3,t3,a5
ffffffffc02007da:	2805                	addiw	a6,a6,1
ffffffffc02007dc:	010e2023          	sw	a6,0(t3)
}
ffffffffc02007e0:	8082                	ret
    nr_free[order]++;
ffffffffc02007e2:	0d8e2803          	lw	a6,216(t3)
ffffffffc02007e6:	40000613          	li	a2,1024
ffffffffc02007ea:	b7e1                	j	ffffffffc02007b2 <buddy_free_pages.part.0+0x98>
        nr_free[order]--;
ffffffffc02007ec:	00005e17          	auipc	t3,0x5
ffffffffc02007f0:	82ce0e13          	addi	t3,t3,-2004 # ffffffffc0205018 <free_area>
ffffffffc02007f4:	0b0e2803          	lw	a6,176(t3)
    int order = 0;
ffffffffc02007f8:	4681                	li	a3,0
ffffffffc02007fa:	b7b1                	j	ffffffffc0200746 <buddy_free_pages.part.0+0x2c>
        size_t block_size = 1U << order;
ffffffffc02007fc:	4605                	li	a2,1
ffffffffc02007fe:	00d6163b          	sllw	a2,a2,a3
ffffffffc0200802:	bf55                	j	ffffffffc02007b6 <buddy_free_pages.part.0+0x9c>

ffffffffc0200804 <buddy_free_pages>:
    assert(n > 0);
ffffffffc0200804:	c191                	beqz	a1,ffffffffc0200808 <buddy_free_pages+0x4>
ffffffffc0200806:	bf11                	j	ffffffffc020071a <buddy_free_pages.part.0>
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200808:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020080a:	00001697          	auipc	a3,0x1
ffffffffc020080e:	f7e68693          	addi	a3,a3,-130 # ffffffffc0201788 <etext+0x288>
ffffffffc0200812:	00001617          	auipc	a2,0x1
ffffffffc0200816:	f7e60613          	addi	a2,a2,-130 # ffffffffc0201790 <etext+0x290>
ffffffffc020081a:	05b00593          	li	a1,91
ffffffffc020081e:	00001517          	auipc	a0,0x1
ffffffffc0200822:	f8a50513          	addi	a0,a0,-118 # ffffffffc02017a8 <etext+0x2a8>
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200826:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200828:	99bff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020082c <buddy_alloc_pages.part.0>:
    while (size < n) {
ffffffffc020082c:	4785                	li	a5,1
    int order = 0;
ffffffffc020082e:	4701                	li	a4,0
    while (size < n) {
ffffffffc0200830:	0ea7f963          	bgeu	a5,a0,ffffffffc0200922 <buddy_alloc_pages.part.0+0xf6>
        size <<= 1;
ffffffffc0200834:	0786                	slli	a5,a5,0x1
        order++;
ffffffffc0200836:	2705                	addiw	a4,a4,1
    while (size < n) {
ffffffffc0200838:	fea7eee3          	bltu	a5,a0,ffffffffc0200834 <buddy_alloc_pages.part.0+0x8>
    int order = 0;
ffffffffc020083c:	4e01                	li	t3,0
    size_t size = 1;
ffffffffc020083e:	4785                	li	a5,1
        size <<= 1;
ffffffffc0200840:	0786                	slli	a5,a5,0x1
        order++;
ffffffffc0200842:	2e05                	addiw	t3,t3,1
    while (size < n) {
ffffffffc0200844:	fea7eee3          	bltu	a5,a0,ffffffffc0200840 <buddy_alloc_pages.part.0+0x14>
    while(order<MAX_ORDER && list_empty(&free_list[order])){
ffffffffc0200848:	47a9                	li	a5,10
ffffffffc020084a:	0ce7c063          	blt	a5,a4,ffffffffc020090a <buddy_alloc_pages.part.0+0xde>
ffffffffc020084e:	00004817          	auipc	a6,0x4
ffffffffc0200852:	7ca80813          	addi	a6,a6,1994 # ffffffffc0205018 <free_area>
ffffffffc0200856:	00471793          	slli	a5,a4,0x4
ffffffffc020085a:	97c2                	add	a5,a5,a6
ffffffffc020085c:	462d                	li	a2,11
ffffffffc020085e:	a029                	j	ffffffffc0200868 <buddy_alloc_pages.part.0+0x3c>
        order++;
ffffffffc0200860:	2705                	addiw	a4,a4,1
    while(order<MAX_ORDER && list_empty(&free_list[order])){
ffffffffc0200862:	07c1                	addi	a5,a5,16
ffffffffc0200864:	0ac70163          	beq	a4,a2,ffffffffc0200906 <buddy_alloc_pages.part.0+0xda>
    return list->next == list;
ffffffffc0200868:	6794                	ld	a3,8(a5)
ffffffffc020086a:	fef68be3          	beq	a3,a5,ffffffffc0200860 <buddy_alloc_pages.part.0+0x34>
    nr_free[order]--;
ffffffffc020086e:	02c70793          	addi	a5,a4,44
ffffffffc0200872:	078a                	slli	a5,a5,0x2
    __list_del(listelm->prev, listelm->next);
ffffffffc0200874:	6288                	ld	a0,0(a3)
ffffffffc0200876:	668c                	ld	a1,8(a3)
ffffffffc0200878:	97c2                	add	a5,a5,a6
ffffffffc020087a:	4390                	lw	a2,0(a5)
    prev->next = next;
ffffffffc020087c:	e50c                	sd	a1,8(a0)
    next->prev = prev;
ffffffffc020087e:	e188                	sd	a0,0(a1)
ffffffffc0200880:	367d                	addiw	a2,a2,-1
ffffffffc0200882:	c390                	sw	a2,0(a5)
    struct Page *p = le2page(list_next(&free_list[order]), page_link);
ffffffffc0200884:	fe868513          	addi	a0,a3,-24
    while(order >alloc_order)
ffffffffc0200888:	08ee5f63          	bge	t3,a4,ffffffffc0200926 <buddy_alloc_pages.part.0+0xfa>
ffffffffc020088c:	fff70613          	addi	a2,a4,-1
ffffffffc0200890:	02b70593          	addi	a1,a4,43
ffffffffc0200894:	0612                	slli	a2,a2,0x4
ffffffffc0200896:	058a                	slli	a1,a1,0x2
ffffffffc0200898:	9642                	add	a2,a2,a6
ffffffffc020089a:	95c2                	add	a1,a1,a6
        struct Page *buddy = p + (1U << order);
ffffffffc020089c:	4f85                	li	t6,1
        order--;
ffffffffc020089e:	377d                	addiw	a4,a4,-1
        struct Page *buddy = p + (1U << order);
ffffffffc02008a0:	00ef98bb          	sllw	a7,t6,a4
ffffffffc02008a4:	02089813          	slli	a6,a7,0x20
ffffffffc02008a8:	02085813          	srli	a6,a6,0x20
ffffffffc02008ac:	00281793          	slli	a5,a6,0x2
ffffffffc02008b0:	97c2                	add	a5,a5,a6
ffffffffc02008b2:	078e                	slli	a5,a5,0x3
ffffffffc02008b4:	97aa                	add	a5,a5,a0
        SetPageProperty(buddy);
ffffffffc02008b6:	0087b803          	ld	a6,8(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc02008ba:	00863e83          	ld	t4,8(a2)
        buddy->property = 1U << order;
ffffffffc02008be:	0117a823          	sw	a7,16(a5)
        SetPageProperty(buddy);
ffffffffc02008c2:	00286813          	ori	a6,a6,2
        nr_free[order]++;
ffffffffc02008c6:	0005a303          	lw	t1,0(a1)
        SetPageProperty(buddy);
ffffffffc02008ca:	0107b423          	sd	a6,8(a5)
        list_add(&free_list[order], &(buddy->page_link));
ffffffffc02008ce:	01878f13          	addi	t5,a5,24
        SetPageProperty(p);
ffffffffc02008d2:	ff06b803          	ld	a6,-16(a3)
    prev->next = next->prev = elm;
ffffffffc02008d6:	01eeb023          	sd	t5,0(t4)
ffffffffc02008da:	01e63423          	sd	t5,8(a2)
    elm->prev = prev;
ffffffffc02008de:	ef90                	sd	a2,24(a5)
    elm->next = next;
ffffffffc02008e0:	03d7b023          	sd	t4,32(a5)
        nr_free[order]++;
ffffffffc02008e4:	0013079b          	addiw	a5,t1,1
ffffffffc02008e8:	c19c                	sw	a5,0(a1)
        SetPageProperty(p);
ffffffffc02008ea:	00286793          	ori	a5,a6,2
        p->property = 1U << order;
ffffffffc02008ee:	ff16ac23          	sw	a7,-8(a3)
        SetPageProperty(p);
ffffffffc02008f2:	fef6b823          	sd	a5,-16(a3)
    while(order >alloc_order)
ffffffffc02008f6:	1641                	addi	a2,a2,-16
ffffffffc02008f8:	15f1                	addi	a1,a1,-4
ffffffffc02008fa:	fbc712e3          	bne	a4,t3,ffffffffc020089e <buddy_alloc_pages.part.0+0x72>
    ClearPageProperty(p);
ffffffffc02008fe:	9bf5                	andi	a5,a5,-3
ffffffffc0200900:	fef6b823          	sd	a5,-16(a3)
    return p;
ffffffffc0200904:	8082                	ret
    if(order==MAX_ORDER) return NULL; // 没有合适的块
ffffffffc0200906:	4501                	li	a0,0
}
ffffffffc0200908:	8082                	ret
    if(order==MAX_ORDER) return NULL; // 没有合适的块
ffffffffc020090a:	47ad                	li	a5,11
ffffffffc020090c:	fef70de3          	beq	a4,a5,ffffffffc0200906 <buddy_alloc_pages.part.0+0xda>
    return listelm->next;
ffffffffc0200910:	00004817          	auipc	a6,0x4
ffffffffc0200914:	70880813          	addi	a6,a6,1800 # ffffffffc0205018 <free_area>
ffffffffc0200918:	00471793          	slli	a5,a4,0x4
ffffffffc020091c:	97c2                	add	a5,a5,a6
ffffffffc020091e:	6794                	ld	a3,8(a5)
ffffffffc0200920:	b7b9                	j	ffffffffc020086e <buddy_alloc_pages.part.0+0x42>
    int order = 0;
ffffffffc0200922:	4e01                	li	t3,0
ffffffffc0200924:	b72d                	j	ffffffffc020084e <buddy_alloc_pages.part.0+0x22>
    ClearPageProperty(p);
ffffffffc0200926:	ff06b783          	ld	a5,-16(a3)
ffffffffc020092a:	bfd1                	j	ffffffffc02008fe <buddy_alloc_pages.part.0+0xd2>

ffffffffc020092c <buddy_alloc_pages>:
    assert(n > 0);
ffffffffc020092c:	c111                	beqz	a0,ffffffffc0200930 <buddy_alloc_pages+0x4>
ffffffffc020092e:	bdfd                	j	ffffffffc020082c <buddy_alloc_pages.part.0>
buddy_alloc_pages(size_t n) {
ffffffffc0200930:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200932:	00001697          	auipc	a3,0x1
ffffffffc0200936:	e5668693          	addi	a3,a3,-426 # ffffffffc0201788 <etext+0x288>
ffffffffc020093a:	00001617          	auipc	a2,0x1
ffffffffc020093e:	e5660613          	addi	a2,a2,-426 # ffffffffc0201790 <etext+0x290>
ffffffffc0200942:	03d00593          	li	a1,61
ffffffffc0200946:	00001517          	auipc	a0,0x1
ffffffffc020094a:	e6250513          	addi	a0,a0,-414 # ffffffffc02017a8 <etext+0x2a8>
buddy_alloc_pages(size_t n) {
ffffffffc020094e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200950:	873ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200954 <buddy_check>:

static void
buddy_check(void) {
ffffffffc0200954:	711d                	addi	sp,sp,-96
ffffffffc0200956:	e4a6                	sd	s1,72(sp)
        size_t block_size = 1U << order;
        while ((le = list_next(le)) != &free_list[order]) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p));
            assert(p->property == block_size);
            assert(((p - pages) & (block_size - 1)) == 0); 
ffffffffc0200958:	00004497          	auipc	s1,0x4
ffffffffc020095c:	6c048493          	addi	s1,s1,1728 # ffffffffc0205018 <free_area>
buddy_check(void) {
ffffffffc0200960:	ec86                	sd	ra,88(sp)
ffffffffc0200962:	e8a2                	sd	s0,80(sp)
ffffffffc0200964:	e0ca                	sd	s2,64(sp)
ffffffffc0200966:	fc4e                	sd	s3,56(sp)
ffffffffc0200968:	f852                	sd	s4,48(sp)
ffffffffc020096a:	f456                	sd	s5,40(sp)
ffffffffc020096c:	f05a                	sd	s6,32(sp)
ffffffffc020096e:	ec5e                	sd	s7,24(sp)
ffffffffc0200970:	e862                	sd	s8,16(sp)
ffffffffc0200972:	e466                	sd	s9,8(sp)
ffffffffc0200974:	e06a                	sd	s10,0(sp)
            assert(((p - pages) & (block_size - 1)) == 0); 
ffffffffc0200976:	00004e17          	auipc	t3,0x4
ffffffffc020097a:	7a2e3e03          	ld	t3,1954(t3) # ffffffffc0205118 <pages>
ffffffffc020097e:	8526                	mv	a0,s1
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc0200980:	4e81                	li	t4,0
    size_t total = 0;
ffffffffc0200982:	4601                	li	a2,0
        size_t block_size = 1U << order;
ffffffffc0200984:	4f05                	li	t5,1
            assert(((p - pages) & (block_size - 1)) == 0); 
ffffffffc0200986:	00001317          	auipc	t1,0x1
ffffffffc020098a:	4ea33303          	ld	t1,1258(t1) # ffffffffc0201e70 <error_string+0x38>
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc020098e:	4fad                	li	t6,11
ffffffffc0200990:	6518                	ld	a4,8(a0)
        size_t block_size = 1U << order;
ffffffffc0200992:	01df15bb          	sllw	a1,t5,t4
ffffffffc0200996:	0005881b          	sext.w	a6,a1
ffffffffc020099a:	1582                	slli	a1,a1,0x20
ffffffffc020099c:	9181                	srli	a1,a1,0x20
        while ((le = list_next(le)) != &free_list[order]) {
ffffffffc020099e:	02a70c63          	beq	a4,a0,ffffffffc02009d6 <buddy_check+0x82>
            assert(((p - pages) & (block_size - 1)) == 0); 
ffffffffc02009a2:	fff58893          	addi	a7,a1,-1
            assert(PageProperty(p));
ffffffffc02009a6:	ff073683          	ld	a3,-16(a4)
            struct Page *p = le2page(le, page_link);
ffffffffc02009aa:	fe870793          	addi	a5,a4,-24
            assert(PageProperty(p));
ffffffffc02009ae:	8a89                	andi	a3,a3,2
ffffffffc02009b0:	28068263          	beqz	a3,ffffffffc0200c34 <buddy_check+0x2e0>
            assert(p->property == block_size);
ffffffffc02009b4:	ff872683          	lw	a3,-8(a4)
ffffffffc02009b8:	29069e63          	bne	a3,a6,ffffffffc0200c54 <buddy_check+0x300>
            assert(((p - pages) & (block_size - 1)) == 0); 
ffffffffc02009bc:	41c787b3          	sub	a5,a5,t3
ffffffffc02009c0:	878d                	srai	a5,a5,0x3
ffffffffc02009c2:	026787b3          	mul	a5,a5,t1
ffffffffc02009c6:	0117f7b3          	and	a5,a5,a7
ffffffffc02009ca:	2a079563          	bnez	a5,ffffffffc0200c74 <buddy_check+0x320>
ffffffffc02009ce:	6718                	ld	a4,8(a4)
            count++;
            total += block_size;
ffffffffc02009d0:	962e                	add	a2,a2,a1
        while ((le = list_next(le)) != &free_list[order]) {
ffffffffc02009d2:	fca71ae3          	bne	a4,a0,ffffffffc02009a6 <buddy_check+0x52>
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc02009d6:	2e85                	addiw	t4,t4,1
ffffffffc02009d8:	0541                	addi	a0,a0,16
ffffffffc02009da:	fbfe9be3          	bne	t4,t6,ffffffffc0200990 <buddy_check+0x3c>
ffffffffc02009de:	00004417          	auipc	s0,0x4
ffffffffc02009e2:	6ea40413          	addi	s0,s0,1770 # ffffffffc02050c8 <free_area+0xb0>
ffffffffc02009e6:	86a2                	mv	a3,s0
    size_t total = 0;
ffffffffc02009e8:	4901                	li	s2,0
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc02009ea:	4701                	li	a4,0
ffffffffc02009ec:	45ad                	li	a1,11
        total += nr_free[order] * (1U << order);
ffffffffc02009ee:	429c                	lw	a5,0(a3)
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc02009f0:	0691                	addi	a3,a3,4
        total += nr_free[order] * (1U << order);
ffffffffc02009f2:	00e797bb          	sllw	a5,a5,a4
ffffffffc02009f6:	1782                	slli	a5,a5,0x20
ffffffffc02009f8:	9381                	srli	a5,a5,0x20
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc02009fa:	2705                	addiw	a4,a4,1
        total += nr_free[order] * (1U << order);
ffffffffc02009fc:	993e                	add	s2,s2,a5
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc02009fe:	feb718e3          	bne	a4,a1,ffffffffc02009ee <buddy_check+0x9a>
        }
    }
    assert(total == buddy_nr_free_pages());
ffffffffc0200a02:	3d261963          	bne	a2,s2,ffffffffc0200dd4 <buddy_check+0x480>
    assert(n > 0);
ffffffffc0200a06:	4505                	li	a0,1
ffffffffc0200a08:	e25ff0ef          	jal	ra,ffffffffc020082c <buddy_alloc_pages.part.0>
ffffffffc0200a0c:	8c2a                	mv	s8,a0
ffffffffc0200a0e:	4505                	li	a0,1
ffffffffc0200a10:	e1dff0ef          	jal	ra,ffffffffc020082c <buddy_alloc_pages.part.0>
ffffffffc0200a14:	8baa                	mv	s7,a0
    
    p0 = p1 = p2 = NULL;
    
    p0 = buddy_alloc_pages(1);
    p1 = buddy_alloc_pages(1);
    assert(p0 != NULL && p1 != NULL);
ffffffffc0200a16:	380c0f63          	beqz	s8,ffffffffc0200db4 <buddy_check+0x460>
ffffffffc0200a1a:	38050d63          	beqz	a0,ffffffffc0200db4 <buddy_check+0x460>
    assert(list_empty(&free_list[0]) && list_empty(&free_list[1]));
ffffffffc0200a1e:	649c                	ld	a5,8(s1)
ffffffffc0200a20:	2a979a63          	bne	a5,s1,ffffffffc0200cd4 <buddy_check+0x380>
ffffffffc0200a24:	6c98                	ld	a4,24(s1)
ffffffffc0200a26:	00004797          	auipc	a5,0x4
ffffffffc0200a2a:	60278793          	addi	a5,a5,1538 # ffffffffc0205028 <free_area+0x10>
ffffffffc0200a2e:	2af71363          	bne	a4,a5,ffffffffc0200cd4 <buddy_check+0x380>
    assert(n > 0);
ffffffffc0200a32:	4505                	li	a0,1
ffffffffc0200a34:	df9ff0ef          	jal	ra,ffffffffc020082c <buddy_alloc_pages.part.0>
    p2 = buddy_alloc_pages(1);
    assert(nr_free[0] == 1 && nr_free[1] == 1 && nr_free[2] == 1 && nr_free[3] == 0);
ffffffffc0200a38:	4705                	li	a4,1
ffffffffc0200a3a:	78d4                	ld	a3,176(s1)
ffffffffc0200a3c:	02071793          	slli	a5,a4,0x20
ffffffffc0200a40:	0785                	addi	a5,a5,1
ffffffffc0200a42:	8d2a                	mv	s10,a0
ffffffffc0200a44:	26f69863          	bne	a3,a5,ffffffffc0200cb4 <buddy_check+0x360>
ffffffffc0200a48:	0b84b983          	ld	s3,184(s1)
ffffffffc0200a4c:	26e99463          	bne	s3,a4,ffffffffc0200cb4 <buddy_check+0x360>
    assert(n > 0);
ffffffffc0200a50:	20000513          	li	a0,512
ffffffffc0200a54:	dd9ff0ef          	jal	ra,ffffffffc020082c <buddy_alloc_pages.part.0>
    struct Page *p3 = buddy_alloc_pages(512);
    assert(nr_free[9] == 1);
ffffffffc0200a58:	0d44a783          	lw	a5,212(s1)
ffffffffc0200a5c:	8b2a                	mv	s6,a0
ffffffffc0200a5e:	3b379b63          	bne	a5,s3,ffffffffc0200e14 <buddy_check+0x4c0>
    assert(n > 0);
ffffffffc0200a62:	20000513          	li	a0,512
ffffffffc0200a66:	dc7ff0ef          	jal	ra,ffffffffc020082c <buddy_alloc_pages.part.0>
ffffffffc0200a6a:	8aaa                	mv	s5,a0
    struct Page *p4 = buddy_alloc_pages(512);
    assert(p3 != NULL && p4 != NULL);
ffffffffc0200a6c:	380b0463          	beqz	s6,ffffffffc0200df4 <buddy_check+0x4a0>
ffffffffc0200a70:	38050263          	beqz	a0,ffffffffc0200df4 <buddy_check+0x4a0>
    assert(n > 0);
ffffffffc0200a74:	40000513          	li	a0,1024
ffffffffc0200a78:	db5ff0ef          	jal	ra,ffffffffc020082c <buddy_alloc_pages.part.0>
    struct Page *p5 = buddy_alloc_pages(1024);
    assert(nr_free[10]==29);
ffffffffc0200a7c:	0d84a703          	lw	a4,216(s1)
ffffffffc0200a80:	47f5                	li	a5,29
ffffffffc0200a82:	8caa                	mv	s9,a0
ffffffffc0200a84:	20f71863          	bne	a4,a5,ffffffffc0200c94 <buddy_check+0x340>
    assert(n > 0);
ffffffffc0200a88:	06400513          	li	a0,100
ffffffffc0200a8c:	da1ff0ef          	jal	ra,ffffffffc020082c <buddy_alloc_pages.part.0>
    struct Page *p6 = buddy_alloc_pages(100);
    assert(list_empty(&free_list[7])&&list_empty(&free_list[6])&&list_empty(&free_list[8])&&list_empty(&free_list[9]));
ffffffffc0200a90:	7cb8                	ld	a4,120(s1)
ffffffffc0200a92:	00004797          	auipc	a5,0x4
ffffffffc0200a96:	5f678793          	addi	a5,a5,1526 # ffffffffc0205088 <free_area+0x70>
ffffffffc0200a9a:	8a2a                	mv	s4,a0
ffffffffc0200a9c:	3cf71c63          	bne	a4,a5,ffffffffc0200e74 <buddy_check+0x520>
ffffffffc0200aa0:	74b8                	ld	a4,104(s1)
ffffffffc0200aa2:	00004797          	auipc	a5,0x4
ffffffffc0200aa6:	5d678793          	addi	a5,a5,1494 # ffffffffc0205078 <free_area+0x60>
ffffffffc0200aaa:	3cf71563          	bne	a4,a5,ffffffffc0200e74 <buddy_check+0x520>
ffffffffc0200aae:	64d8                	ld	a4,136(s1)
ffffffffc0200ab0:	00004797          	auipc	a5,0x4
ffffffffc0200ab4:	5e878793          	addi	a5,a5,1512 # ffffffffc0205098 <free_area+0x80>
ffffffffc0200ab8:	3af71e63          	bne	a4,a5,ffffffffc0200e74 <buddy_check+0x520>
ffffffffc0200abc:	6cd8                	ld	a4,152(s1)
ffffffffc0200abe:	00004797          	auipc	a5,0x4
ffffffffc0200ac2:	5ea78793          	addi	a5,a5,1514 # ffffffffc02050a8 <free_area+0x90>
ffffffffc0200ac6:	3af71763          	bne	a4,a5,ffffffffc0200e74 <buddy_check+0x520>
    assert(n > 0);
ffffffffc0200aca:	03e00513          	li	a0,62
ffffffffc0200ace:	d5fff0ef          	jal	ra,ffffffffc020082c <buddy_alloc_pages.part.0>
ffffffffc0200ad2:	89aa                	mv	s3,a0
    struct Page *p7 = buddy_alloc_pages(62);
    assert(p6 != NULL && p7 != NULL);
ffffffffc0200ad4:	2c0a0063          	beqz	s4,ffffffffc0200d94 <buddy_check+0x440>
ffffffffc0200ad8:	2a050e63          	beqz	a0,ffffffffc0200d94 <buddy_check+0x440>
    assert(n > 0);
ffffffffc0200adc:	6505                	lui	a0,0x1
ffffffffc0200ade:	80050513          	addi	a0,a0,-2048 # 800 <kern_entry-0xffffffffc01ff800>
ffffffffc0200ae2:	d4bff0ef          	jal	ra,ffffffffc020082c <buddy_alloc_pages.part.0>
    struct Page *p8 = buddy_alloc_pages(2048);
    assert(p8 == NULL);
ffffffffc0200ae6:	28051763          	bnez	a0,ffffffffc0200d74 <buddy_check+0x420>
    assert(n > 0);
ffffffffc0200aea:	4585                	li	a1,1
ffffffffc0200aec:	8562                	mv	a0,s8
ffffffffc0200aee:	c2dff0ef          	jal	ra,ffffffffc020071a <buddy_free_pages.part.0>
ffffffffc0200af2:	4585                	li	a1,1
ffffffffc0200af4:	855e                	mv	a0,s7
ffffffffc0200af6:	c25ff0ef          	jal	ra,ffffffffc020071a <buddy_free_pages.part.0>
  
    buddy_free_pages(p0, 1);
    buddy_free_pages(p1, 1);
    assert(nr_free[1] == 2);
ffffffffc0200afa:	0b44a703          	lw	a4,180(s1)
ffffffffc0200afe:	4789                	li	a5,2
ffffffffc0200b00:	24f71a63          	bne	a4,a5,ffffffffc0200d54 <buddy_check+0x400>
    assert(n > 0);
ffffffffc0200b04:	4585                	li	a1,1
ffffffffc0200b06:	856a                	mv	a0,s10
ffffffffc0200b08:	c13ff0ef          	jal	ra,ffffffffc020071a <buddy_free_pages.part.0>
    buddy_free_pages(p2, 1);
    assert(nr_free[1] == 1 && nr_free[2] == 0 && nr_free[3] == 1);
ffffffffc0200b0c:	0b44a783          	lw	a5,180(s1)
ffffffffc0200b10:	4705                	li	a4,1
ffffffffc0200b12:	22e79163          	bne	a5,a4,ffffffffc0200d34 <buddy_check+0x3e0>
ffffffffc0200b16:	7cd8                	ld	a4,184(s1)
ffffffffc0200b18:	1782                	slli	a5,a5,0x20
ffffffffc0200b1a:	20f71d63          	bne	a4,a5,ffffffffc0200d34 <buddy_check+0x3e0>
    assert(n > 0);
ffffffffc0200b1e:	20000593          	li	a1,512
ffffffffc0200b22:	855a                	mv	a0,s6
ffffffffc0200b24:	bf7ff0ef          	jal	ra,ffffffffc020071a <buddy_free_pages.part.0>
ffffffffc0200b28:	20000593          	li	a1,512
ffffffffc0200b2c:	8556                	mv	a0,s5
ffffffffc0200b2e:	bedff0ef          	jal	ra,ffffffffc020071a <buddy_free_pages.part.0>
    buddy_free_pages(p3, 512);
    buddy_free_pages(p4, 512);
    assert(nr_free[10] == 29);
ffffffffc0200b32:	0d84a703          	lw	a4,216(s1)
ffffffffc0200b36:	47f5                	li	a5,29
ffffffffc0200b38:	1cf71e63          	bne	a4,a5,ffffffffc0200d14 <buddy_check+0x3c0>
    assert(n > 0);
ffffffffc0200b3c:	40000593          	li	a1,1024
ffffffffc0200b40:	8566                	mv	a0,s9
ffffffffc0200b42:	bd9ff0ef          	jal	ra,ffffffffc020071a <buddy_free_pages.part.0>
ffffffffc0200b46:	08000593          	li	a1,128
ffffffffc0200b4a:	8552                	mv	a0,s4
ffffffffc0200b4c:	bcfff0ef          	jal	ra,ffffffffc020071a <buddy_free_pages.part.0>
ffffffffc0200b50:	04000593          	li	a1,64
ffffffffc0200b54:	854e                	mv	a0,s3
ffffffffc0200b56:	bc5ff0ef          	jal	ra,ffffffffc020071a <buddy_free_pages.part.0>
    buddy_free_pages(p5, 1024);
    buddy_free_pages(p6, 128);
    buddy_free_pages(p7, 64);
    assert(nr_free[6] == 0 && nr_free[8] == 0 && nr_free[9] == 0);
ffffffffc0200b5a:	0c84a783          	lw	a5,200(s1)
ffffffffc0200b5e:	18079b63          	bnez	a5,ffffffffc0200cf4 <buddy_check+0x3a0>
ffffffffc0200b62:	68f0                	ld	a2,208(s1)
ffffffffc0200b64:	00004697          	auipc	a3,0x4
ffffffffc0200b68:	56468693          	addi	a3,a3,1380 # ffffffffc02050c8 <free_area+0xb0>
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc0200b6c:	4701                	li	a4,0
ffffffffc0200b6e:	45ad                	li	a1,11
    assert(nr_free[6] == 0 && nr_free[8] == 0 && nr_free[9] == 0);
ffffffffc0200b70:	18061263          	bnez	a2,ffffffffc0200cf4 <buddy_check+0x3a0>
        total += nr_free[order] * (1U << order);
ffffffffc0200b74:	429c                	lw	a5,0(a3)
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc0200b76:	0691                	addi	a3,a3,4
        total += nr_free[order] * (1U << order);
ffffffffc0200b78:	00e797bb          	sllw	a5,a5,a4
ffffffffc0200b7c:	1782                	slli	a5,a5,0x20
ffffffffc0200b7e:	9381                	srli	a5,a5,0x20
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc0200b80:	2705                	addiw	a4,a4,1
        total += nr_free[order] * (1U << order);
ffffffffc0200b82:	963e                	add	a2,a2,a5
    for (int order = 0; order < MAX_ORDER; order++) {
ffffffffc0200b84:	feb718e3          	bne	a4,a1,ffffffffc0200b74 <buddy_check+0x220>
    assert(buddy_nr_free_pages() == total);
ffffffffc0200b88:	2cc91663          	bne	s2,a2,ffffffffc0200e54 <buddy_check+0x500>
    assert(n > 0);
ffffffffc0200b8c:	20000513          	li	a0,512
ffffffffc0200b90:	c9dff0ef          	jal	ra,ffffffffc020082c <buddy_alloc_pages.part.0>
ffffffffc0200b94:	8b2a                	mv	s6,a0
ffffffffc0200b96:	20000513          	li	a0,512
ffffffffc0200b9a:	c93ff0ef          	jal	ra,ffffffffc020082c <buddy_alloc_pages.part.0>
ffffffffc0200b9e:	8aaa                	mv	s5,a0
ffffffffc0200ba0:	40000513          	li	a0,1024
ffffffffc0200ba4:	c89ff0ef          	jal	ra,ffffffffc020082c <buddy_alloc_pages.part.0>
ffffffffc0200ba8:	8a2a                	mv	s4,a0
ffffffffc0200baa:	06400513          	li	a0,100
ffffffffc0200bae:	c7fff0ef          	jal	ra,ffffffffc020082c <buddy_alloc_pages.part.0>
ffffffffc0200bb2:	89aa                	mv	s3,a0
ffffffffc0200bb4:	03e00513          	li	a0,62
ffffffffc0200bb8:	c75ff0ef          	jal	ra,ffffffffc020082c <buddy_alloc_pages.part.0>
ffffffffc0200bbc:	20000593          	li	a1,512
ffffffffc0200bc0:	892a                	mv	s2,a0
ffffffffc0200bc2:	855a                	mv	a0,s6
    assert(n > 0);
ffffffffc0200bc4:	b57ff0ef          	jal	ra,ffffffffc020071a <buddy_free_pages.part.0>
ffffffffc0200bc8:	20000593          	li	a1,512
ffffffffc0200bcc:	8556                	mv	a0,s5
ffffffffc0200bce:	b4dff0ef          	jal	ra,ffffffffc020071a <buddy_free_pages.part.0>
    p5 = buddy_alloc_pages(1024);
    p6 = buddy_alloc_pages(100);
    p7 = buddy_alloc_pages(62);
  buddy_free_pages(p3, 512);
    buddy_free_pages(p4, 512);
    assert(nr_free[10] == 29);
ffffffffc0200bd2:	0d84a703          	lw	a4,216(s1)
ffffffffc0200bd6:	47f5                	li	a5,29
ffffffffc0200bd8:	24f71e63          	bne	a4,a5,ffffffffc0200e34 <buddy_check+0x4e0>
    assert(n > 0);
ffffffffc0200bdc:	40000593          	li	a1,1024
ffffffffc0200be0:	8552                	mv	a0,s4
ffffffffc0200be2:	b39ff0ef          	jal	ra,ffffffffc020071a <buddy_free_pages.part.0>
ffffffffc0200be6:	08000593          	li	a1,128
ffffffffc0200bea:	854e                	mv	a0,s3
ffffffffc0200bec:	b2fff0ef          	jal	ra,ffffffffc020071a <buddy_free_pages.part.0>
ffffffffc0200bf0:	854a                	mv	a0,s2
ffffffffc0200bf2:	04000593          	li	a1,64
ffffffffc0200bf6:	b25ff0ef          	jal	ra,ffffffffc020071a <buddy_free_pages.part.0>
    buddy_free_pages(p5, 1024);
    buddy_free_pages(p6, 128);
    buddy_free_pages(p7, 64);
 for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200bfa:	00004917          	auipc	s2,0x4
ffffffffc0200bfe:	4fa90913          	addi	s2,s2,1274 # ffffffffc02050f4 <free_area+0xdc>
        free_cnt += nr_free[i] * (1U << i);
        cprintf("%d \n",nr_free[i]);
ffffffffc0200c02:	00001497          	auipc	s1,0x1
ffffffffc0200c06:	e8e48493          	addi	s1,s1,-370 # ffffffffc0201a90 <etext+0x590>
ffffffffc0200c0a:	400c                	lw	a1,0(s0)
ffffffffc0200c0c:	8526                	mv	a0,s1
 for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200c0e:	0411                	addi	s0,s0,4
        cprintf("%d \n",nr_free[i]);
ffffffffc0200c10:	d3cff0ef          	jal	ra,ffffffffc020014c <cprintf>
 for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200c14:	ff241be3          	bne	s0,s2,ffffffffc0200c0a <buddy_check+0x2b6>
    }
    
}
ffffffffc0200c18:	60e6                	ld	ra,88(sp)
ffffffffc0200c1a:	6446                	ld	s0,80(sp)
ffffffffc0200c1c:	64a6                	ld	s1,72(sp)
ffffffffc0200c1e:	6906                	ld	s2,64(sp)
ffffffffc0200c20:	79e2                	ld	s3,56(sp)
ffffffffc0200c22:	7a42                	ld	s4,48(sp)
ffffffffc0200c24:	7aa2                	ld	s5,40(sp)
ffffffffc0200c26:	7b02                	ld	s6,32(sp)
ffffffffc0200c28:	6be2                	ld	s7,24(sp)
ffffffffc0200c2a:	6c42                	ld	s8,16(sp)
ffffffffc0200c2c:	6ca2                	ld	s9,8(sp)
ffffffffc0200c2e:	6d02                	ld	s10,0(sp)
ffffffffc0200c30:	6125                	addi	sp,sp,96
ffffffffc0200c32:	8082                	ret
            assert(PageProperty(p));
ffffffffc0200c34:	00001697          	auipc	a3,0x1
ffffffffc0200c38:	ba468693          	addi	a3,a3,-1116 # ffffffffc02017d8 <etext+0x2d8>
ffffffffc0200c3c:	00001617          	auipc	a2,0x1
ffffffffc0200c40:	b5460613          	addi	a2,a2,-1196 # ffffffffc0201790 <etext+0x290>
ffffffffc0200c44:	08f00593          	li	a1,143
ffffffffc0200c48:	00001517          	auipc	a0,0x1
ffffffffc0200c4c:	b6050513          	addi	a0,a0,-1184 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200c50:	d72ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(p->property == block_size);
ffffffffc0200c54:	00001697          	auipc	a3,0x1
ffffffffc0200c58:	b9468693          	addi	a3,a3,-1132 # ffffffffc02017e8 <etext+0x2e8>
ffffffffc0200c5c:	00001617          	auipc	a2,0x1
ffffffffc0200c60:	b3460613          	addi	a2,a2,-1228 # ffffffffc0201790 <etext+0x290>
ffffffffc0200c64:	09000593          	li	a1,144
ffffffffc0200c68:	00001517          	auipc	a0,0x1
ffffffffc0200c6c:	b4050513          	addi	a0,a0,-1216 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200c70:	d52ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(((p - pages) & (block_size - 1)) == 0); 
ffffffffc0200c74:	00001697          	auipc	a3,0x1
ffffffffc0200c78:	b9468693          	addi	a3,a3,-1132 # ffffffffc0201808 <etext+0x308>
ffffffffc0200c7c:	00001617          	auipc	a2,0x1
ffffffffc0200c80:	b1460613          	addi	a2,a2,-1260 # ffffffffc0201790 <etext+0x290>
ffffffffc0200c84:	09100593          	li	a1,145
ffffffffc0200c88:	00001517          	auipc	a0,0x1
ffffffffc0200c8c:	b2050513          	addi	a0,a0,-1248 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200c90:	d32ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free[10]==29);
ffffffffc0200c94:	00001697          	auipc	a3,0x1
ffffffffc0200c98:	c9468693          	addi	a3,a3,-876 # ffffffffc0201928 <etext+0x428>
ffffffffc0200c9c:	00001617          	auipc	a2,0x1
ffffffffc0200ca0:	af460613          	addi	a2,a2,-1292 # ffffffffc0201790 <etext+0x290>
ffffffffc0200ca4:	0a700593          	li	a1,167
ffffffffc0200ca8:	00001517          	auipc	a0,0x1
ffffffffc0200cac:	b0050513          	addi	a0,a0,-1280 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200cb0:	d12ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free[0] == 1 && nr_free[1] == 1 && nr_free[2] == 1 && nr_free[3] == 0);
ffffffffc0200cb4:	00001697          	auipc	a3,0x1
ffffffffc0200cb8:	bf468693          	addi	a3,a3,-1036 # ffffffffc02018a8 <etext+0x3a8>
ffffffffc0200cbc:	00001617          	auipc	a2,0x1
ffffffffc0200cc0:	ad460613          	addi	a2,a2,-1324 # ffffffffc0201790 <etext+0x290>
ffffffffc0200cc4:	0a100593          	li	a1,161
ffffffffc0200cc8:	00001517          	auipc	a0,0x1
ffffffffc0200ccc:	ae050513          	addi	a0,a0,-1312 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200cd0:	cf2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(list_empty(&free_list[0]) && list_empty(&free_list[1]));
ffffffffc0200cd4:	00001697          	auipc	a3,0x1
ffffffffc0200cd8:	b9c68693          	addi	a3,a3,-1124 # ffffffffc0201870 <etext+0x370>
ffffffffc0200cdc:	00001617          	auipc	a2,0x1
ffffffffc0200ce0:	ab460613          	addi	a2,a2,-1356 # ffffffffc0201790 <etext+0x290>
ffffffffc0200ce4:	09f00593          	li	a1,159
ffffffffc0200ce8:	00001517          	auipc	a0,0x1
ffffffffc0200cec:	ac050513          	addi	a0,a0,-1344 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200cf0:	cd2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free[6] == 0 && nr_free[8] == 0 && nr_free[9] == 0);
ffffffffc0200cf4:	00001697          	auipc	a3,0x1
ffffffffc0200cf8:	d4468693          	addi	a3,a3,-700 # ffffffffc0201a38 <etext+0x538>
ffffffffc0200cfc:	00001617          	auipc	a2,0x1
ffffffffc0200d00:	a9460613          	addi	a2,a2,-1388 # ffffffffc0201790 <etext+0x290>
ffffffffc0200d04:	0ba00593          	li	a1,186
ffffffffc0200d08:	00001517          	auipc	a0,0x1
ffffffffc0200d0c:	aa050513          	addi	a0,a0,-1376 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200d10:	cb2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free[10] == 29);
ffffffffc0200d14:	00001697          	auipc	a3,0x1
ffffffffc0200d18:	d0c68693          	addi	a3,a3,-756 # ffffffffc0201a20 <etext+0x520>
ffffffffc0200d1c:	00001617          	auipc	a2,0x1
ffffffffc0200d20:	a7460613          	addi	a2,a2,-1420 # ffffffffc0201790 <etext+0x290>
ffffffffc0200d24:	0b600593          	li	a1,182
ffffffffc0200d28:	00001517          	auipc	a0,0x1
ffffffffc0200d2c:	a8050513          	addi	a0,a0,-1408 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200d30:	c92ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free[1] == 1 && nr_free[2] == 0 && nr_free[3] == 1);
ffffffffc0200d34:	00001697          	auipc	a3,0x1
ffffffffc0200d38:	cb468693          	addi	a3,a3,-844 # ffffffffc02019e8 <etext+0x4e8>
ffffffffc0200d3c:	00001617          	auipc	a2,0x1
ffffffffc0200d40:	a5460613          	addi	a2,a2,-1452 # ffffffffc0201790 <etext+0x290>
ffffffffc0200d44:	0b300593          	li	a1,179
ffffffffc0200d48:	00001517          	auipc	a0,0x1
ffffffffc0200d4c:	a6050513          	addi	a0,a0,-1440 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200d50:	c72ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free[1] == 2);
ffffffffc0200d54:	00001697          	auipc	a3,0x1
ffffffffc0200d58:	c8468693          	addi	a3,a3,-892 # ffffffffc02019d8 <etext+0x4d8>
ffffffffc0200d5c:	00001617          	auipc	a2,0x1
ffffffffc0200d60:	a3460613          	addi	a2,a2,-1484 # ffffffffc0201790 <etext+0x290>
ffffffffc0200d64:	0b100593          	li	a1,177
ffffffffc0200d68:	00001517          	auipc	a0,0x1
ffffffffc0200d6c:	a4050513          	addi	a0,a0,-1472 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200d70:	c52ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p8 == NULL);
ffffffffc0200d74:	00001697          	auipc	a3,0x1
ffffffffc0200d78:	c5468693          	addi	a3,a3,-940 # ffffffffc02019c8 <etext+0x4c8>
ffffffffc0200d7c:	00001617          	auipc	a2,0x1
ffffffffc0200d80:	a1460613          	addi	a2,a2,-1516 # ffffffffc0201790 <etext+0x290>
ffffffffc0200d84:	0ad00593          	li	a1,173
ffffffffc0200d88:	00001517          	auipc	a0,0x1
ffffffffc0200d8c:	a2050513          	addi	a0,a0,-1504 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200d90:	c32ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p6 != NULL && p7 != NULL);
ffffffffc0200d94:	00001697          	auipc	a3,0x1
ffffffffc0200d98:	c1468693          	addi	a3,a3,-1004 # ffffffffc02019a8 <etext+0x4a8>
ffffffffc0200d9c:	00001617          	auipc	a2,0x1
ffffffffc0200da0:	9f460613          	addi	a2,a2,-1548 # ffffffffc0201790 <etext+0x290>
ffffffffc0200da4:	0ab00593          	li	a1,171
ffffffffc0200da8:	00001517          	auipc	a0,0x1
ffffffffc0200dac:	a0050513          	addi	a0,a0,-1536 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200db0:	c12ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != NULL && p1 != NULL);
ffffffffc0200db4:	00001697          	auipc	a3,0x1
ffffffffc0200db8:	a9c68693          	addi	a3,a3,-1380 # ffffffffc0201850 <etext+0x350>
ffffffffc0200dbc:	00001617          	auipc	a2,0x1
ffffffffc0200dc0:	9d460613          	addi	a2,a2,-1580 # ffffffffc0201790 <etext+0x290>
ffffffffc0200dc4:	09e00593          	li	a1,158
ffffffffc0200dc8:	00001517          	auipc	a0,0x1
ffffffffc0200dcc:	9e050513          	addi	a0,a0,-1568 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200dd0:	bf2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == buddy_nr_free_pages());
ffffffffc0200dd4:	00001697          	auipc	a3,0x1
ffffffffc0200dd8:	a5c68693          	addi	a3,a3,-1444 # ffffffffc0201830 <etext+0x330>
ffffffffc0200ddc:	00001617          	auipc	a2,0x1
ffffffffc0200de0:	9b460613          	addi	a2,a2,-1612 # ffffffffc0201790 <etext+0x290>
ffffffffc0200de4:	09600593          	li	a1,150
ffffffffc0200de8:	00001517          	auipc	a0,0x1
ffffffffc0200dec:	9c050513          	addi	a0,a0,-1600 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200df0:	bd2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p3 != NULL && p4 != NULL);
ffffffffc0200df4:	00001697          	auipc	a3,0x1
ffffffffc0200df8:	b1468693          	addi	a3,a3,-1260 # ffffffffc0201908 <etext+0x408>
ffffffffc0200dfc:	00001617          	auipc	a2,0x1
ffffffffc0200e00:	99460613          	addi	a2,a2,-1644 # ffffffffc0201790 <etext+0x290>
ffffffffc0200e04:	0a500593          	li	a1,165
ffffffffc0200e08:	00001517          	auipc	a0,0x1
ffffffffc0200e0c:	9a050513          	addi	a0,a0,-1632 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200e10:	bb2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free[9] == 1);
ffffffffc0200e14:	00001697          	auipc	a3,0x1
ffffffffc0200e18:	ae468693          	addi	a3,a3,-1308 # ffffffffc02018f8 <etext+0x3f8>
ffffffffc0200e1c:	00001617          	auipc	a2,0x1
ffffffffc0200e20:	97460613          	addi	a2,a2,-1676 # ffffffffc0201790 <etext+0x290>
ffffffffc0200e24:	0a300593          	li	a1,163
ffffffffc0200e28:	00001517          	auipc	a0,0x1
ffffffffc0200e2c:	98050513          	addi	a0,a0,-1664 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200e30:	b92ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free[10] == 29);
ffffffffc0200e34:	00001697          	auipc	a3,0x1
ffffffffc0200e38:	bec68693          	addi	a3,a3,-1044 # ffffffffc0201a20 <etext+0x520>
ffffffffc0200e3c:	00001617          	auipc	a2,0x1
ffffffffc0200e40:	95460613          	addi	a2,a2,-1708 # ffffffffc0201790 <etext+0x290>
ffffffffc0200e44:	0c300593          	li	a1,195
ffffffffc0200e48:	00001517          	auipc	a0,0x1
ffffffffc0200e4c:	96050513          	addi	a0,a0,-1696 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200e50:	b72ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(buddy_nr_free_pages() == total);
ffffffffc0200e54:	00001697          	auipc	a3,0x1
ffffffffc0200e58:	c1c68693          	addi	a3,a3,-996 # ffffffffc0201a70 <etext+0x570>
ffffffffc0200e5c:	00001617          	auipc	a2,0x1
ffffffffc0200e60:	93460613          	addi	a2,a2,-1740 # ffffffffc0201790 <etext+0x290>
ffffffffc0200e64:	0bb00593          	li	a1,187
ffffffffc0200e68:	00001517          	auipc	a0,0x1
ffffffffc0200e6c:	94050513          	addi	a0,a0,-1728 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200e70:	b52ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(list_empty(&free_list[7])&&list_empty(&free_list[6])&&list_empty(&free_list[8])&&list_empty(&free_list[9]));
ffffffffc0200e74:	00001697          	auipc	a3,0x1
ffffffffc0200e78:	ac468693          	addi	a3,a3,-1340 # ffffffffc0201938 <etext+0x438>
ffffffffc0200e7c:	00001617          	auipc	a2,0x1
ffffffffc0200e80:	91460613          	addi	a2,a2,-1772 # ffffffffc0201790 <etext+0x290>
ffffffffc0200e84:	0a900593          	li	a1,169
ffffffffc0200e88:	00001517          	auipc	a0,0x1
ffffffffc0200e8c:	92050513          	addi	a0,a0,-1760 # ffffffffc02017a8 <etext+0x2a8>
ffffffffc0200e90:	b32ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200e94 <pmm_init>:

static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    pmm_manager = &buddy_manager;
ffffffffc0200e94:	00001797          	auipc	a5,0x1
ffffffffc0200e98:	c1478793          	addi	a5,a5,-1004 # ffffffffc0201aa8 <buddy_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200e9c:	638c                	ld	a1,0(a5)
        
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200e9e:	7179                	addi	sp,sp,-48
ffffffffc0200ea0:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200ea2:	00001517          	auipc	a0,0x1
ffffffffc0200ea6:	c3e50513          	addi	a0,a0,-962 # ffffffffc0201ae0 <buddy_manager+0x38>
    pmm_manager = &buddy_manager;
ffffffffc0200eaa:	00004417          	auipc	s0,0x4
ffffffffc0200eae:	27640413          	addi	s0,s0,630 # ffffffffc0205120 <pmm_manager>
void pmm_init(void) {
ffffffffc0200eb2:	f406                	sd	ra,40(sp)
ffffffffc0200eb4:	ec26                	sd	s1,24(sp)
ffffffffc0200eb6:	e44e                	sd	s3,8(sp)
ffffffffc0200eb8:	e84a                	sd	s2,16(sp)
ffffffffc0200eba:	e052                	sd	s4,0(sp)
    pmm_manager = &buddy_manager;
ffffffffc0200ebc:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200ebe:	a8eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0200ec2:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200ec4:	00004497          	auipc	s1,0x4
ffffffffc0200ec8:	27448493          	addi	s1,s1,628 # ffffffffc0205138 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200ecc:	679c                	ld	a5,8(a5)
ffffffffc0200ece:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200ed0:	57f5                	li	a5,-3
ffffffffc0200ed2:	07fa                	slli	a5,a5,0x1e
ffffffffc0200ed4:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200ed6:	ee6ff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0200eda:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200edc:	eeaff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200ee0:	14050d63          	beqz	a0,ffffffffc020103a <pmm_init+0x1a6>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200ee4:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200ee6:	00001517          	auipc	a0,0x1
ffffffffc0200eea:	c4250513          	addi	a0,a0,-958 # ffffffffc0201b28 <buddy_manager+0x80>
ffffffffc0200eee:	a5eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200ef2:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200ef6:	864e                	mv	a2,s3
ffffffffc0200ef8:	fffa0693          	addi	a3,s4,-1
ffffffffc0200efc:	85ca                	mv	a1,s2
ffffffffc0200efe:	00001517          	auipc	a0,0x1
ffffffffc0200f02:	c4250513          	addi	a0,a0,-958 # ffffffffc0201b40 <buddy_manager+0x98>
ffffffffc0200f06:	a46ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200f0a:	c80007b7          	lui	a5,0xc8000
ffffffffc0200f0e:	8652                	mv	a2,s4
ffffffffc0200f10:	0d47e463          	bltu	a5,s4,ffffffffc0200fd8 <pmm_init+0x144>
ffffffffc0200f14:	00005797          	auipc	a5,0x5
ffffffffc0200f18:	22b78793          	addi	a5,a5,555 # ffffffffc020613f <end+0xfff>
ffffffffc0200f1c:	757d                	lui	a0,0xfffff
ffffffffc0200f1e:	8d7d                	and	a0,a0,a5
ffffffffc0200f20:	8231                	srli	a2,a2,0xc
ffffffffc0200f22:	00004797          	auipc	a5,0x4
ffffffffc0200f26:	1ec7b723          	sd	a2,494(a5) # ffffffffc0205110 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200f2a:	00004797          	auipc	a5,0x4
ffffffffc0200f2e:	1ea7b723          	sd	a0,494(a5) # ffffffffc0205118 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200f32:	000807b7          	lui	a5,0x80
ffffffffc0200f36:	002005b7          	lui	a1,0x200
ffffffffc0200f3a:	02f60563          	beq	a2,a5,ffffffffc0200f64 <pmm_init+0xd0>
ffffffffc0200f3e:	00261593          	slli	a1,a2,0x2
ffffffffc0200f42:	00c586b3          	add	a3,a1,a2
ffffffffc0200f46:	fec007b7          	lui	a5,0xfec00
ffffffffc0200f4a:	97aa                	add	a5,a5,a0
ffffffffc0200f4c:	068e                	slli	a3,a3,0x3
ffffffffc0200f4e:	96be                	add	a3,a3,a5
ffffffffc0200f50:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc0200f52:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200f54:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9faee8>
        SetPageReserved(pages + i);
ffffffffc0200f58:	00176713          	ori	a4,a4,1
ffffffffc0200f5c:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200f60:	fef699e3          	bne	a3,a5,ffffffffc0200f52 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200f64:	95b2                	add	a1,a1,a2
ffffffffc0200f66:	fec006b7          	lui	a3,0xfec00
ffffffffc0200f6a:	96aa                	add	a3,a3,a0
ffffffffc0200f6c:	058e                	slli	a1,a1,0x3
ffffffffc0200f6e:	96ae                	add	a3,a3,a1
ffffffffc0200f70:	c02007b7          	lui	a5,0xc0200
ffffffffc0200f74:	0af6e763          	bltu	a3,a5,ffffffffc0201022 <pmm_init+0x18e>
ffffffffc0200f78:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200f7a:	77fd                	lui	a5,0xfffff
ffffffffc0200f7c:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200f80:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200f82:	04b6ee63          	bltu	a3,a1,ffffffffc0200fde <pmm_init+0x14a>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200f86:	601c                	ld	a5,0(s0)
ffffffffc0200f88:	7b9c                	ld	a5,48(a5)
ffffffffc0200f8a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200f8c:	00001517          	auipc	a0,0x1
ffffffffc0200f90:	c3c50513          	addi	a0,a0,-964 # ffffffffc0201bc8 <buddy_manager+0x120>
ffffffffc0200f94:	9b8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200f98:	00003597          	auipc	a1,0x3
ffffffffc0200f9c:	06858593          	addi	a1,a1,104 # ffffffffc0204000 <boot_page_table_sv39>
ffffffffc0200fa0:	00004797          	auipc	a5,0x4
ffffffffc0200fa4:	18b7b823          	sd	a1,400(a5) # ffffffffc0205130 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200fa8:	c02007b7          	lui	a5,0xc0200
ffffffffc0200fac:	0af5e363          	bltu	a1,a5,ffffffffc0201052 <pmm_init+0x1be>
ffffffffc0200fb0:	6090                	ld	a2,0(s1)
}
ffffffffc0200fb2:	7402                	ld	s0,32(sp)
ffffffffc0200fb4:	70a2                	ld	ra,40(sp)
ffffffffc0200fb6:	64e2                	ld	s1,24(sp)
ffffffffc0200fb8:	6942                	ld	s2,16(sp)
ffffffffc0200fba:	69a2                	ld	s3,8(sp)
ffffffffc0200fbc:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200fbe:	40c58633          	sub	a2,a1,a2
ffffffffc0200fc2:	00004797          	auipc	a5,0x4
ffffffffc0200fc6:	16c7b323          	sd	a2,358(a5) # ffffffffc0205128 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200fca:	00001517          	auipc	a0,0x1
ffffffffc0200fce:	c1e50513          	addi	a0,a0,-994 # ffffffffc0201be8 <buddy_manager+0x140>
}
ffffffffc0200fd2:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200fd4:	978ff06f          	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200fd8:	c8000637          	lui	a2,0xc8000
ffffffffc0200fdc:	bf25                	j	ffffffffc0200f14 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200fde:	6705                	lui	a4,0x1
ffffffffc0200fe0:	177d                	addi	a4,a4,-1
ffffffffc0200fe2:	96ba                	add	a3,a3,a4
ffffffffc0200fe4:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200fe6:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200fea:	02c7f063          	bgeu	a5,a2,ffffffffc020100a <pmm_init+0x176>
    pmm_manager->init_memmap(base, n);
ffffffffc0200fee:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200ff0:	fff80737          	lui	a4,0xfff80
ffffffffc0200ff4:	973e                	add	a4,a4,a5
ffffffffc0200ff6:	00271793          	slli	a5,a4,0x2
ffffffffc0200ffa:	97ba                	add	a5,a5,a4
ffffffffc0200ffc:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200ffe:	8d95                	sub	a1,a1,a3
ffffffffc0201000:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201002:	81b1                	srli	a1,a1,0xc
ffffffffc0201004:	953e                	add	a0,a0,a5
ffffffffc0201006:	9702                	jalr	a4
}
ffffffffc0201008:	bfbd                	j	ffffffffc0200f86 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc020100a:	00001617          	auipc	a2,0x1
ffffffffc020100e:	b8e60613          	addi	a2,a2,-1138 # ffffffffc0201b98 <buddy_manager+0xf0>
ffffffffc0201012:	06a00593          	li	a1,106
ffffffffc0201016:	00001517          	auipc	a0,0x1
ffffffffc020101a:	ba250513          	addi	a0,a0,-1118 # ffffffffc0201bb8 <buddy_manager+0x110>
ffffffffc020101e:	9a4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201022:	00001617          	auipc	a2,0x1
ffffffffc0201026:	b4e60613          	addi	a2,a2,-1202 # ffffffffc0201b70 <buddy_manager+0xc8>
ffffffffc020102a:	05f00593          	li	a1,95
ffffffffc020102e:	00001517          	auipc	a0,0x1
ffffffffc0201032:	aea50513          	addi	a0,a0,-1302 # ffffffffc0201b18 <buddy_manager+0x70>
ffffffffc0201036:	98cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc020103a:	00001617          	auipc	a2,0x1
ffffffffc020103e:	abe60613          	addi	a2,a2,-1346 # ffffffffc0201af8 <buddy_manager+0x50>
ffffffffc0201042:	04700593          	li	a1,71
ffffffffc0201046:	00001517          	auipc	a0,0x1
ffffffffc020104a:	ad250513          	addi	a0,a0,-1326 # ffffffffc0201b18 <buddy_manager+0x70>
ffffffffc020104e:	974ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201052:	86ae                	mv	a3,a1
ffffffffc0201054:	00001617          	auipc	a2,0x1
ffffffffc0201058:	b1c60613          	addi	a2,a2,-1252 # ffffffffc0201b70 <buddy_manager+0xc8>
ffffffffc020105c:	07b00593          	li	a1,123
ffffffffc0201060:	00001517          	auipc	a0,0x1
ffffffffc0201064:	ab850513          	addi	a0,a0,-1352 # ffffffffc0201b18 <buddy_manager+0x70>
ffffffffc0201068:	95aff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020106c <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020106c:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201070:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201072:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201076:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201078:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020107c:	f022                	sd	s0,32(sp)
ffffffffc020107e:	ec26                	sd	s1,24(sp)
ffffffffc0201080:	e84a                	sd	s2,16(sp)
ffffffffc0201082:	f406                	sd	ra,40(sp)
ffffffffc0201084:	e44e                	sd	s3,8(sp)
ffffffffc0201086:	84aa                	mv	s1,a0
ffffffffc0201088:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020108a:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020108e:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201090:	03067e63          	bgeu	a2,a6,ffffffffc02010cc <printnum+0x60>
ffffffffc0201094:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201096:	00805763          	blez	s0,ffffffffc02010a4 <printnum+0x38>
ffffffffc020109a:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020109c:	85ca                	mv	a1,s2
ffffffffc020109e:	854e                	mv	a0,s3
ffffffffc02010a0:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02010a2:	fc65                	bnez	s0,ffffffffc020109a <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02010a4:	1a02                	slli	s4,s4,0x20
ffffffffc02010a6:	00001797          	auipc	a5,0x1
ffffffffc02010aa:	b8278793          	addi	a5,a5,-1150 # ffffffffc0201c28 <buddy_manager+0x180>
ffffffffc02010ae:	020a5a13          	srli	s4,s4,0x20
ffffffffc02010b2:	9a3e                	add	s4,s4,a5
}
ffffffffc02010b4:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02010b6:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02010ba:	70a2                	ld	ra,40(sp)
ffffffffc02010bc:	69a2                	ld	s3,8(sp)
ffffffffc02010be:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02010c0:	85ca                	mv	a1,s2
ffffffffc02010c2:	87a6                	mv	a5,s1
}
ffffffffc02010c4:	6942                	ld	s2,16(sp)
ffffffffc02010c6:	64e2                	ld	s1,24(sp)
ffffffffc02010c8:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02010ca:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02010cc:	03065633          	divu	a2,a2,a6
ffffffffc02010d0:	8722                	mv	a4,s0
ffffffffc02010d2:	f9bff0ef          	jal	ra,ffffffffc020106c <printnum>
ffffffffc02010d6:	b7f9                	j	ffffffffc02010a4 <printnum+0x38>

ffffffffc02010d8 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02010d8:	7119                	addi	sp,sp,-128
ffffffffc02010da:	f4a6                	sd	s1,104(sp)
ffffffffc02010dc:	f0ca                	sd	s2,96(sp)
ffffffffc02010de:	ecce                	sd	s3,88(sp)
ffffffffc02010e0:	e8d2                	sd	s4,80(sp)
ffffffffc02010e2:	e4d6                	sd	s5,72(sp)
ffffffffc02010e4:	e0da                	sd	s6,64(sp)
ffffffffc02010e6:	fc5e                	sd	s7,56(sp)
ffffffffc02010e8:	f06a                	sd	s10,32(sp)
ffffffffc02010ea:	fc86                	sd	ra,120(sp)
ffffffffc02010ec:	f8a2                	sd	s0,112(sp)
ffffffffc02010ee:	f862                	sd	s8,48(sp)
ffffffffc02010f0:	f466                	sd	s9,40(sp)
ffffffffc02010f2:	ec6e                	sd	s11,24(sp)
ffffffffc02010f4:	892a                	mv	s2,a0
ffffffffc02010f6:	84ae                	mv	s1,a1
ffffffffc02010f8:	8d32                	mv	s10,a2
ffffffffc02010fa:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02010fc:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201100:	5b7d                	li	s6,-1
ffffffffc0201102:	00001a97          	auipc	s5,0x1
ffffffffc0201106:	b5aa8a93          	addi	s5,s5,-1190 # ffffffffc0201c5c <buddy_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020110a:	00001b97          	auipc	s7,0x1
ffffffffc020110e:	d2eb8b93          	addi	s7,s7,-722 # ffffffffc0201e38 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201112:	000d4503          	lbu	a0,0(s10)
ffffffffc0201116:	001d0413          	addi	s0,s10,1
ffffffffc020111a:	01350a63          	beq	a0,s3,ffffffffc020112e <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020111e:	c121                	beqz	a0,ffffffffc020115e <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201120:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201122:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201124:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201126:	fff44503          	lbu	a0,-1(s0)
ffffffffc020112a:	ff351ae3          	bne	a0,s3,ffffffffc020111e <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020112e:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201132:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201136:	4c81                	li	s9,0
ffffffffc0201138:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020113a:	5c7d                	li	s8,-1
ffffffffc020113c:	5dfd                	li	s11,-1
ffffffffc020113e:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201142:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201144:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201148:	0ff5f593          	zext.b	a1,a1
ffffffffc020114c:	00140d13          	addi	s10,s0,1
ffffffffc0201150:	04b56263          	bltu	a0,a1,ffffffffc0201194 <vprintfmt+0xbc>
ffffffffc0201154:	058a                	slli	a1,a1,0x2
ffffffffc0201156:	95d6                	add	a1,a1,s5
ffffffffc0201158:	4194                	lw	a3,0(a1)
ffffffffc020115a:	96d6                	add	a3,a3,s5
ffffffffc020115c:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020115e:	70e6                	ld	ra,120(sp)
ffffffffc0201160:	7446                	ld	s0,112(sp)
ffffffffc0201162:	74a6                	ld	s1,104(sp)
ffffffffc0201164:	7906                	ld	s2,96(sp)
ffffffffc0201166:	69e6                	ld	s3,88(sp)
ffffffffc0201168:	6a46                	ld	s4,80(sp)
ffffffffc020116a:	6aa6                	ld	s5,72(sp)
ffffffffc020116c:	6b06                	ld	s6,64(sp)
ffffffffc020116e:	7be2                	ld	s7,56(sp)
ffffffffc0201170:	7c42                	ld	s8,48(sp)
ffffffffc0201172:	7ca2                	ld	s9,40(sp)
ffffffffc0201174:	7d02                	ld	s10,32(sp)
ffffffffc0201176:	6de2                	ld	s11,24(sp)
ffffffffc0201178:	6109                	addi	sp,sp,128
ffffffffc020117a:	8082                	ret
            padc = '0';
ffffffffc020117c:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc020117e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201182:	846a                	mv	s0,s10
ffffffffc0201184:	00140d13          	addi	s10,s0,1
ffffffffc0201188:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020118c:	0ff5f593          	zext.b	a1,a1
ffffffffc0201190:	fcb572e3          	bgeu	a0,a1,ffffffffc0201154 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201194:	85a6                	mv	a1,s1
ffffffffc0201196:	02500513          	li	a0,37
ffffffffc020119a:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020119c:	fff44783          	lbu	a5,-1(s0)
ffffffffc02011a0:	8d22                	mv	s10,s0
ffffffffc02011a2:	f73788e3          	beq	a5,s3,ffffffffc0201112 <vprintfmt+0x3a>
ffffffffc02011a6:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02011aa:	1d7d                	addi	s10,s10,-1
ffffffffc02011ac:	ff379de3          	bne	a5,s3,ffffffffc02011a6 <vprintfmt+0xce>
ffffffffc02011b0:	b78d                	j	ffffffffc0201112 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02011b2:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02011b6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02011ba:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02011bc:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02011c0:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02011c4:	02d86463          	bltu	a6,a3,ffffffffc02011ec <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02011c8:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02011cc:	002c169b          	slliw	a3,s8,0x2
ffffffffc02011d0:	0186873b          	addw	a4,a3,s8
ffffffffc02011d4:	0017171b          	slliw	a4,a4,0x1
ffffffffc02011d8:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02011da:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02011de:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02011e0:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02011e4:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02011e8:	fed870e3          	bgeu	a6,a3,ffffffffc02011c8 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02011ec:	f40ddce3          	bgez	s11,ffffffffc0201144 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02011f0:	8de2                	mv	s11,s8
ffffffffc02011f2:	5c7d                	li	s8,-1
ffffffffc02011f4:	bf81                	j	ffffffffc0201144 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02011f6:	fffdc693          	not	a3,s11
ffffffffc02011fa:	96fd                	srai	a3,a3,0x3f
ffffffffc02011fc:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201200:	00144603          	lbu	a2,1(s0)
ffffffffc0201204:	2d81                	sext.w	s11,s11
ffffffffc0201206:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201208:	bf35                	j	ffffffffc0201144 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020120a:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020120e:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201212:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201214:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201216:	bfd9                	j	ffffffffc02011ec <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201218:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020121a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020121e:	01174463          	blt	a4,a7,ffffffffc0201226 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201222:	1a088e63          	beqz	a7,ffffffffc02013de <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201226:	000a3603          	ld	a2,0(s4)
ffffffffc020122a:	46c1                	li	a3,16
ffffffffc020122c:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020122e:	2781                	sext.w	a5,a5
ffffffffc0201230:	876e                	mv	a4,s11
ffffffffc0201232:	85a6                	mv	a1,s1
ffffffffc0201234:	854a                	mv	a0,s2
ffffffffc0201236:	e37ff0ef          	jal	ra,ffffffffc020106c <printnum>
            break;
ffffffffc020123a:	bde1                	j	ffffffffc0201112 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020123c:	000a2503          	lw	a0,0(s4)
ffffffffc0201240:	85a6                	mv	a1,s1
ffffffffc0201242:	0a21                	addi	s4,s4,8
ffffffffc0201244:	9902                	jalr	s2
            break;
ffffffffc0201246:	b5f1                	j	ffffffffc0201112 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201248:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020124a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020124e:	01174463          	blt	a4,a7,ffffffffc0201256 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201252:	18088163          	beqz	a7,ffffffffc02013d4 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201256:	000a3603          	ld	a2,0(s4)
ffffffffc020125a:	46a9                	li	a3,10
ffffffffc020125c:	8a2e                	mv	s4,a1
ffffffffc020125e:	bfc1                	j	ffffffffc020122e <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201260:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201264:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201266:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201268:	bdf1                	j	ffffffffc0201144 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020126a:	85a6                	mv	a1,s1
ffffffffc020126c:	02500513          	li	a0,37
ffffffffc0201270:	9902                	jalr	s2
            break;
ffffffffc0201272:	b545                	j	ffffffffc0201112 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201274:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201278:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020127a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020127c:	b5e1                	j	ffffffffc0201144 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc020127e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201280:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201284:	01174463          	blt	a4,a7,ffffffffc020128c <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201288:	14088163          	beqz	a7,ffffffffc02013ca <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020128c:	000a3603          	ld	a2,0(s4)
ffffffffc0201290:	46a1                	li	a3,8
ffffffffc0201292:	8a2e                	mv	s4,a1
ffffffffc0201294:	bf69                	j	ffffffffc020122e <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201296:	03000513          	li	a0,48
ffffffffc020129a:	85a6                	mv	a1,s1
ffffffffc020129c:	e03e                	sd	a5,0(sp)
ffffffffc020129e:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02012a0:	85a6                	mv	a1,s1
ffffffffc02012a2:	07800513          	li	a0,120
ffffffffc02012a6:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02012a8:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02012aa:	6782                	ld	a5,0(sp)
ffffffffc02012ac:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02012ae:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02012b2:	bfb5                	j	ffffffffc020122e <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02012b4:	000a3403          	ld	s0,0(s4)
ffffffffc02012b8:	008a0713          	addi	a4,s4,8
ffffffffc02012bc:	e03a                	sd	a4,0(sp)
ffffffffc02012be:	14040263          	beqz	s0,ffffffffc0201402 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02012c2:	0fb05763          	blez	s11,ffffffffc02013b0 <vprintfmt+0x2d8>
ffffffffc02012c6:	02d00693          	li	a3,45
ffffffffc02012ca:	0cd79163          	bne	a5,a3,ffffffffc020138c <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02012ce:	00044783          	lbu	a5,0(s0)
ffffffffc02012d2:	0007851b          	sext.w	a0,a5
ffffffffc02012d6:	cf85                	beqz	a5,ffffffffc020130e <vprintfmt+0x236>
ffffffffc02012d8:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02012dc:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02012e0:	000c4563          	bltz	s8,ffffffffc02012ea <vprintfmt+0x212>
ffffffffc02012e4:	3c7d                	addiw	s8,s8,-1
ffffffffc02012e6:	036c0263          	beq	s8,s6,ffffffffc020130a <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02012ea:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02012ec:	0e0c8e63          	beqz	s9,ffffffffc02013e8 <vprintfmt+0x310>
ffffffffc02012f0:	3781                	addiw	a5,a5,-32
ffffffffc02012f2:	0ef47b63          	bgeu	s0,a5,ffffffffc02013e8 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02012f6:	03f00513          	li	a0,63
ffffffffc02012fa:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02012fc:	000a4783          	lbu	a5,0(s4)
ffffffffc0201300:	3dfd                	addiw	s11,s11,-1
ffffffffc0201302:	0a05                	addi	s4,s4,1
ffffffffc0201304:	0007851b          	sext.w	a0,a5
ffffffffc0201308:	ffe1                	bnez	a5,ffffffffc02012e0 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020130a:	01b05963          	blez	s11,ffffffffc020131c <vprintfmt+0x244>
ffffffffc020130e:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201310:	85a6                	mv	a1,s1
ffffffffc0201312:	02000513          	li	a0,32
ffffffffc0201316:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201318:	fe0d9be3          	bnez	s11,ffffffffc020130e <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020131c:	6a02                	ld	s4,0(sp)
ffffffffc020131e:	bbd5                	j	ffffffffc0201112 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201320:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201322:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201326:	01174463          	blt	a4,a7,ffffffffc020132e <vprintfmt+0x256>
    else if (lflag) {
ffffffffc020132a:	08088d63          	beqz	a7,ffffffffc02013c4 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020132e:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201332:	0a044d63          	bltz	s0,ffffffffc02013ec <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201336:	8622                	mv	a2,s0
ffffffffc0201338:	8a66                	mv	s4,s9
ffffffffc020133a:	46a9                	li	a3,10
ffffffffc020133c:	bdcd                	j	ffffffffc020122e <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020133e:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201342:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201344:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201346:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020134a:	8fb5                	xor	a5,a5,a3
ffffffffc020134c:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201350:	02d74163          	blt	a4,a3,ffffffffc0201372 <vprintfmt+0x29a>
ffffffffc0201354:	00369793          	slli	a5,a3,0x3
ffffffffc0201358:	97de                	add	a5,a5,s7
ffffffffc020135a:	639c                	ld	a5,0(a5)
ffffffffc020135c:	cb99                	beqz	a5,ffffffffc0201372 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc020135e:	86be                	mv	a3,a5
ffffffffc0201360:	00001617          	auipc	a2,0x1
ffffffffc0201364:	8f860613          	addi	a2,a2,-1800 # ffffffffc0201c58 <buddy_manager+0x1b0>
ffffffffc0201368:	85a6                	mv	a1,s1
ffffffffc020136a:	854a                	mv	a0,s2
ffffffffc020136c:	0ce000ef          	jal	ra,ffffffffc020143a <printfmt>
ffffffffc0201370:	b34d                	j	ffffffffc0201112 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201372:	00001617          	auipc	a2,0x1
ffffffffc0201376:	8d660613          	addi	a2,a2,-1834 # ffffffffc0201c48 <buddy_manager+0x1a0>
ffffffffc020137a:	85a6                	mv	a1,s1
ffffffffc020137c:	854a                	mv	a0,s2
ffffffffc020137e:	0bc000ef          	jal	ra,ffffffffc020143a <printfmt>
ffffffffc0201382:	bb41                	j	ffffffffc0201112 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201384:	00001417          	auipc	s0,0x1
ffffffffc0201388:	8bc40413          	addi	s0,s0,-1860 # ffffffffc0201c40 <buddy_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020138c:	85e2                	mv	a1,s8
ffffffffc020138e:	8522                	mv	a0,s0
ffffffffc0201390:	e43e                	sd	a5,8(sp)
ffffffffc0201392:	0fc000ef          	jal	ra,ffffffffc020148e <strnlen>
ffffffffc0201396:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020139a:	01b05b63          	blez	s11,ffffffffc02013b0 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020139e:	67a2                	ld	a5,8(sp)
ffffffffc02013a0:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02013a4:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02013a6:	85a6                	mv	a1,s1
ffffffffc02013a8:	8552                	mv	a0,s4
ffffffffc02013aa:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02013ac:	fe0d9ce3          	bnez	s11,ffffffffc02013a4 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013b0:	00044783          	lbu	a5,0(s0)
ffffffffc02013b4:	00140a13          	addi	s4,s0,1
ffffffffc02013b8:	0007851b          	sext.w	a0,a5
ffffffffc02013bc:	d3a5                	beqz	a5,ffffffffc020131c <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02013be:	05e00413          	li	s0,94
ffffffffc02013c2:	bf39                	j	ffffffffc02012e0 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02013c4:	000a2403          	lw	s0,0(s4)
ffffffffc02013c8:	b7ad                	j	ffffffffc0201332 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02013ca:	000a6603          	lwu	a2,0(s4)
ffffffffc02013ce:	46a1                	li	a3,8
ffffffffc02013d0:	8a2e                	mv	s4,a1
ffffffffc02013d2:	bdb1                	j	ffffffffc020122e <vprintfmt+0x156>
ffffffffc02013d4:	000a6603          	lwu	a2,0(s4)
ffffffffc02013d8:	46a9                	li	a3,10
ffffffffc02013da:	8a2e                	mv	s4,a1
ffffffffc02013dc:	bd89                	j	ffffffffc020122e <vprintfmt+0x156>
ffffffffc02013de:	000a6603          	lwu	a2,0(s4)
ffffffffc02013e2:	46c1                	li	a3,16
ffffffffc02013e4:	8a2e                	mv	s4,a1
ffffffffc02013e6:	b5a1                	j	ffffffffc020122e <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02013e8:	9902                	jalr	s2
ffffffffc02013ea:	bf09                	j	ffffffffc02012fc <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02013ec:	85a6                	mv	a1,s1
ffffffffc02013ee:	02d00513          	li	a0,45
ffffffffc02013f2:	e03e                	sd	a5,0(sp)
ffffffffc02013f4:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02013f6:	6782                	ld	a5,0(sp)
ffffffffc02013f8:	8a66                	mv	s4,s9
ffffffffc02013fa:	40800633          	neg	a2,s0
ffffffffc02013fe:	46a9                	li	a3,10
ffffffffc0201400:	b53d                	j	ffffffffc020122e <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201402:	03b05163          	blez	s11,ffffffffc0201424 <vprintfmt+0x34c>
ffffffffc0201406:	02d00693          	li	a3,45
ffffffffc020140a:	f6d79de3          	bne	a5,a3,ffffffffc0201384 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020140e:	00001417          	auipc	s0,0x1
ffffffffc0201412:	83240413          	addi	s0,s0,-1998 # ffffffffc0201c40 <buddy_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201416:	02800793          	li	a5,40
ffffffffc020141a:	02800513          	li	a0,40
ffffffffc020141e:	00140a13          	addi	s4,s0,1
ffffffffc0201422:	bd6d                	j	ffffffffc02012dc <vprintfmt+0x204>
ffffffffc0201424:	00001a17          	auipc	s4,0x1
ffffffffc0201428:	81da0a13          	addi	s4,s4,-2019 # ffffffffc0201c41 <buddy_manager+0x199>
ffffffffc020142c:	02800513          	li	a0,40
ffffffffc0201430:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201434:	05e00413          	li	s0,94
ffffffffc0201438:	b565                	j	ffffffffc02012e0 <vprintfmt+0x208>

ffffffffc020143a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020143a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020143c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201440:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201442:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201444:	ec06                	sd	ra,24(sp)
ffffffffc0201446:	f83a                	sd	a4,48(sp)
ffffffffc0201448:	fc3e                	sd	a5,56(sp)
ffffffffc020144a:	e0c2                	sd	a6,64(sp)
ffffffffc020144c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020144e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201450:	c89ff0ef          	jal	ra,ffffffffc02010d8 <vprintfmt>
}
ffffffffc0201454:	60e2                	ld	ra,24(sp)
ffffffffc0201456:	6161                	addi	sp,sp,80
ffffffffc0201458:	8082                	ret

ffffffffc020145a <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020145a:	4781                	li	a5,0
ffffffffc020145c:	00004717          	auipc	a4,0x4
ffffffffc0201460:	bb473703          	ld	a4,-1100(a4) # ffffffffc0205010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201464:	88ba                	mv	a7,a4
ffffffffc0201466:	852a                	mv	a0,a0
ffffffffc0201468:	85be                	mv	a1,a5
ffffffffc020146a:	863e                	mv	a2,a5
ffffffffc020146c:	00000073          	ecall
ffffffffc0201470:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201472:	8082                	ret

ffffffffc0201474 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201474:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201478:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc020147a:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc020147c:	cb81                	beqz	a5,ffffffffc020148c <strlen+0x18>
        cnt ++;
ffffffffc020147e:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201480:	00a707b3          	add	a5,a4,a0
ffffffffc0201484:	0007c783          	lbu	a5,0(a5)
ffffffffc0201488:	fbfd                	bnez	a5,ffffffffc020147e <strlen+0xa>
ffffffffc020148a:	8082                	ret
    }
    return cnt;
}
ffffffffc020148c:	8082                	ret

ffffffffc020148e <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020148e:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201490:	e589                	bnez	a1,ffffffffc020149a <strnlen+0xc>
ffffffffc0201492:	a811                	j	ffffffffc02014a6 <strnlen+0x18>
        cnt ++;
ffffffffc0201494:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201496:	00f58863          	beq	a1,a5,ffffffffc02014a6 <strnlen+0x18>
ffffffffc020149a:	00f50733          	add	a4,a0,a5
ffffffffc020149e:	00074703          	lbu	a4,0(a4)
ffffffffc02014a2:	fb6d                	bnez	a4,ffffffffc0201494 <strnlen+0x6>
ffffffffc02014a4:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02014a6:	852e                	mv	a0,a1
ffffffffc02014a8:	8082                	ret

ffffffffc02014aa <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02014aa:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02014ae:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02014b2:	cb89                	beqz	a5,ffffffffc02014c4 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02014b4:	0505                	addi	a0,a0,1
ffffffffc02014b6:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02014b8:	fee789e3          	beq	a5,a4,ffffffffc02014aa <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02014bc:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02014c0:	9d19                	subw	a0,a0,a4
ffffffffc02014c2:	8082                	ret
ffffffffc02014c4:	4501                	li	a0,0
ffffffffc02014c6:	bfed                	j	ffffffffc02014c0 <strcmp+0x16>

ffffffffc02014c8 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02014c8:	c20d                	beqz	a2,ffffffffc02014ea <strncmp+0x22>
ffffffffc02014ca:	962e                	add	a2,a2,a1
ffffffffc02014cc:	a031                	j	ffffffffc02014d8 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02014ce:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02014d0:	00e79a63          	bne	a5,a4,ffffffffc02014e4 <strncmp+0x1c>
ffffffffc02014d4:	00b60b63          	beq	a2,a1,ffffffffc02014ea <strncmp+0x22>
ffffffffc02014d8:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02014dc:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02014de:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02014e2:	f7f5                	bnez	a5,ffffffffc02014ce <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02014e4:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02014e8:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02014ea:	4501                	li	a0,0
ffffffffc02014ec:	8082                	ret

ffffffffc02014ee <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02014ee:	ca01                	beqz	a2,ffffffffc02014fe <memset+0x10>
ffffffffc02014f0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02014f2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02014f4:	0785                	addi	a5,a5,1
ffffffffc02014f6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02014fa:	fec79de3          	bne	a5,a2,ffffffffc02014f4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02014fe:	8082                	ret
